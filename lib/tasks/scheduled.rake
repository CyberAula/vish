# encoding: utf-8

namespace :scheduled do

  #Usage
  #Development:   bundle exec rake scheduled:recalculateRankingMetrics
  #In production: bundle exec rake scheduled:recalculateRankingMetrics RAILS_ENV=production
  task :recalculateRankingMetrics => :environment do
    puts "Recalculate ranking metrics"
    timeStart = Time.now

    #1. Recalculate popularity
    Rake::Task["scheduled:recalculatePopularity"].invoke

    #2. Recalculate ranking metrics
    puts "Recalculating ranking metrics"

    modelCoefficients = {}
    modelCoefficients[:Excursion] = 1
    modelCoefficients[:Resource] = 0.9
    modelCoefficients[:User] = 0.9
    modelCoefficients[:Event] = 0.9

    #Since Sphinx does not support signed integers, we have to store the ranking metric in a positive scale.
    #ao.popularity is in a scale [0,1000000]
    #ao.qscore is in a scale [0,1000000]
    #ao_ranking will be in a scale [0,1000000]
    #We will take into account qscore only for resources
    
    resourceAOTypes = ["Document", "Excursion", "Webapp", "Scormfile","Link","Embed"]
    resourceAOs = ActivityObject.where("object_type in (?)", resourceAOTypes)
    nonResourceAOs = ActivityObject.where("object_type not in (?)", resourceAOTypes)

    resourceRankingWeights = {}
    resourceRankingWeights[:popularity] = 0.7
    resourceRankingWeights[:qscore] = 0.3

    resourceAOs.all.each do |ao|
      ao_ranking = resourceRankingWeights[:popularity] * ao.popularity +  resourceRankingWeights[:qscore] * ao.qscore
      ao.update_column :ranking, ao_ranking
    end

    nonResourceAOs.all.each do |ao|
      ao.ranking = ao.popularity

      if ao.object_type == "Actor"
        ao.ranking = ao.ranking * modelCoefficients[:User]
      elsif ao.object_type == "Event"
        ao.ranking = ao.ranking * modelCoefficients[:Event]
      end

      ao.update_column :ranking, ao.ranking
    end

    #3. Fit ranking metrics
    #Needed to compare different models using the ranking metrics
    #Popularity metric has been corrected in the recalculate popularity method.
    puts "Fitting scores and applying correction coefficients"

    metricsScaleFactor = 1000000

    maxRankingForResources = [resourceAOs.max_by {|ao| ao.ranking }.ranking,1].max
    resourcesCoefficient = (1*metricsScaleFactor)/maxRankingForResources.to_f

    resourceAOs.each do |ao|
      ao.ranking = ao.ranking * resourcesCoefficient
      if ao.object_type == "Excursion"
        ao.ranking = ao.ranking * modelCoefficients[:Excursion]
      else
        ao.ranking = ao.ranking * modelCoefficients[:Resource]
      end
      ao.update_column :ranking, ao.ranking
    end

    timeFinish = Time.now
    puts "Recalculating ranking metrics: Task finished"
    puts "Elapsed time: " + (timeFinish - timeStart).round(1).to_s + " (s)"
  end

  #Usage
  #Development:   bundle exec rake scheduled:recalculatePopularity
  #In production: bundle exec rake scheduled:recalculatePopularity RAILS_ENV=production
	task :recalculatePopularity => :environment do
    puts "Recalculating popularity"
    timeStart = Time.now

    # This task recalculates popularity in Activity Objects
    # Object types of Activity Objects:
    # ["Actor", "Post", "Comment", "Category", "Document", "Excursion", "Link", "Event", "Embed", "Webapp", "Scormfile"]

    resourceAOs = ActivityObject.where("object_type in (?)", ["Document", "Excursion", "Webapp", "Scormfile","Link","Embed"])
    userAOs = ActivityObject.joins(:actor).where("activity_objects.object_type='Actor' and actors.subject_type='User'")
    eventAOs = ActivityObject.where("object_type in (?)", ["Event"])
    # categoryAOs = ActivityObject.where("object_type in (?)", ["Category"])

    windowLength = 2592000 #1 month
    #Change windowLength to 2 months
    windowLength = windowLength * 2

    #Popularity is calculated in a 0-1 scale.
    #We have to convert it to an integer.
    # metricsScaleFactor = 1000000 will store 6 significative numbers
    metricsScaleFactor = 1000000

    #################################
    #First. Resource popularity
    #################################
    puts "Recalculating resources popularity"

    resourceWeights = {}
    resourceWeights[:fVisits] = 0.4
    resourceWeights[:fDownloads] = 0.1
    resourceWeights[:fLikes] = 0.5

    #Specify different weights for resources that can't be downloaded:
    nonDownloableResources = ["Link", "Embed"]
    linkWeights = {}
    linkWeights[:fVisits] = 0.4
    linkWeights[:fDownloads] = 0
    linkWeights[:fLikes] = 0.6
    
    #Get values to normalize scores
    resource_maxVisitCount = [resourceAOs.maximum(:visit_count),1].max
    resource_maxDownloadCount = [resourceAOs.maximum(:download_count),1].max
    resource_maxLikeCount = [resourceAOs.maximum(:like_count),1].max

    resourceAOs.each do |ao|
      timeWindow = [(Time.now - ao.updated_at)/windowLength.to_f,0.5].max
      fVisits = (ao.visit_count/timeWindow.to_f)/resource_maxVisitCount
      fDownloads = (ao.download_count/timeWindow.to_f)/resource_maxDownloadCount
      fLikes = (ao.like_count/timeWindow.to_f)/resource_maxLikeCount

      if(nonDownloableResources.include? ao.object_type)
        rWeights = linkWeights
      else
        rWeights = resourceWeights
      end

      ao.popularity = ((rWeights[:fVisits] * fVisits + rWeights[:fDownloads] * fDownloads + rWeights[:fLikes] * fLikes)*metricsScaleFactor).round(0)
    end

    ###################################
    ###Step 2. Users popularity
    ###################################
    puts "Recalculating users popularity"

    userWeights = {}
    userWeights[:followerCount] = 0.4
    userWeights[:resourcesPopularity] = 0.6

    #Get values to normalize scores
    user_maxFollowerCount = [userAOs.maximum(:follower_count),1].max
    user_maxResourcesPopularity = [userAOs.map{|ao| 
      Excursion.authored_by(ao.object).map{|e| e.popularity}.sum
    }.max,1].max

    userAOs.each do |ao|
      uFollowers = ao.follower_count/user_maxFollowerCount.to_f
      uResourcesPopularity = (Excursion.authored_by(ao.object).map{|e| e.popularity}.sum)/user_maxResourcesPopularity.to_f

      ao.popularity = ((userWeights[:followerCount] * uFollowers + userWeights[:resourcesPopularity] * uResourcesPopularity)*metricsScaleFactor).round(0)
    end

    ###################################
    ###Step 3. Events popularity
    ###################################
    puts "Recalculating events popularity"

    eventWeights = {}
    eventWeights[:fVisits] = 0.5
    eventWeights[:fLikes] = 0.5

    #Get values to normalize scores
    events_maxVisitCount = [eventAOs.maximum(:visit_count),1].max
    events_maxLikeCount = [eventAOs.maximum(:like_count),1].max

    eventAOs.each do |ao|
      timeWindow = [(Time.now - ao.updated_at)/windowLength.to_f,0.5].max
      fVisits = (ao.visit_count/timeWindow.to_f)/events_maxVisitCount
      fLikes = (ao.like_count/timeWindow.to_f)/events_maxLikeCount

      ao.popularity = ((eventWeights[:fVisits] * fVisits + eventWeights[:fLikes] * fLikes)*metricsScaleFactor).round(0)
    end

    ##############
    # Fit scores to the [0,1] scale [Excursion with highest popularity will have a popularity of 1]
    # Apply coefficients to give some models more importance than others
    ##############
    puts "Fitting scores and applying correction coefficients"

    modelCoefficients = {}
    modelCoefficients[:Excursion] = 1
    modelCoefficients[:Resource] = 0.9
    modelCoefficients[:User] = 0.8
    modelCoefficients[:Event] = 0.1
    
    maxPopularityForResources = [resourceAOs.max_by {|ao| ao.popularity }.popularity,1].max
    maxPopularityForUsers = [userAOs.max_by {|ao| ao.popularity }.popularity,1].max
    maxPopularityForEvents = [eventAOs.max_by {|ao| ao.popularity }.popularity,1].max

    resourcesCoefficient = (1*metricsScaleFactor)/maxPopularityForResources.to_f
    usersCoefficient = (1*metricsScaleFactor)/maxPopularityForUsers.to_f
    eventsCoefficient = (1*metricsScaleFactor)/maxPopularityForEvents.to_f

    resourceAOs.each do |ao|
      ao.popularity = ao.popularity * resourcesCoefficient
      if ao.object_type == "Excursion"
        ao.popularity = ao.popularity * modelCoefficients[:Excursion]
      else
        ao.popularity = ao.popularity * modelCoefficients[:Resource]
      end
      ao.update_column :popularity, ao.popularity
    end

    userAOs.each do |ao|
      ao.popularity = ao.popularity * usersCoefficient * modelCoefficients[:User]
      ao.update_column :popularity, ao.popularity
    end

    eventAOs.each do |ao|
      ao.popularity = ao.popularity * eventsCoefficient * modelCoefficients[:Event]
      ao.update_column :popularity, ao.popularity
    end

    timeFinish = Time.now
    puts "Recalculating popularity: Task finished"
    puts "Elapsed time: " + (timeFinish - timeStart).round(1).to_s + " (s)"
	end

  #Usage
  #Development:   bundle exec rake scheduled:resetRankingMetrics
  #In production: bundle exec rake scheduled:resetRankingMetrics RAILS_ENV=production
  task :resetRankingMetrics => :environment do
    puts "Reset popularity and updating quality scores"
    
    ActivityObject.all.each do |ao|
      ao.update_column :popularity, 0
      ao.update_column :ranking, 0
      ao.calculate_qscore
    end

    Rake::Task["scheduled:recalculateRankingMetrics"].invoke

    puts "Task finished"
  end

end
