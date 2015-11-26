# encoding: utf-8

namespace :scheduled do

  #Usage
  #Development:   bundle exec rake scheduled:recalculateRankingMetrics
  #In production: bundle exec rake scheduled:recalculateRankingMetrics RAILS_ENV=production
  task :recalculateRankingMetrics => :environment do
    puts "Recalculating ranking metrics"
    timeStart = Time.now

    #1. Recalculate popularity
    Rake::Task["scheduled:recalculatePopularity"].invoke

    #2. Recalculate ranking metrics
    puts "Recalculating ranking values"

    modelCoefficients = {}
    modelCoefficients[:Excursion] = 1
    modelCoefficients[:Resource] = 0.9
    modelCoefficients[:User] = 0.9
    modelCoefficients[:Event] = 0.9
    modelCoefficients[:Category] = 0.9
    
    #Since Sphinx does not support signed integers, we have to store the ranking metric in a positive scale.
    #ao.popularity is in a scale [0,1000000]
    #ao.qscore is in a scale [0,1000000]
    #ao.ranking will be in a scale [0,1000000]
    #We will take into account qscore only for resources (and categories). 
    #For non resource aos, ranking will be calculated based on popularity

    resourceAOTypes = VishConfig.getAvailableResourceModels
    #["Document", "Webapp", "Scormfile", "Link", "Embed", "Writing", "Excursion", "Workshop"]
    if VishConfig.getAvailableMainModels.include? "Category"
      #Treat categories like resources for ranking metrics
      resourceAOTypes += ["Category"]
    end

    resourceAOs = ActivityObject.where("object_type in (?)", resourceAOTypes)
    nonResourceAOs = ActivityObject.where("object_type not in (?)", resourceAOTypes)

    if VishConfig.getAvailableMainModels.include? "Category"
      #Calculate qscore for categories
      ActivityObject.where("object_type in (?)", ["Category"]).all.each do |ao|
        ao.object.calculate_qscore unless ao.object.nil?
      end
    end

    resourceRankingWeights = {}
    resourceRankingWeights[:popularity] = 0.7
    resourceRankingWeights[:qscore] = 0.3

    resourceAOs.all.each do |ao|
      ao.ranking = resourceRankingWeights[:popularity] * ao.popularity +  resourceRankingWeights[:qscore] * ao.qscore
      ao.update_column :ranking, ao.ranking
    end

    nonResourceAOs.all.each do |ao|
      case ao.object_type
      when "Actor"
        ao.ranking = ao.popularity * modelCoefficients[:User]
      when "Event"
        ao.ranking = ao.popularity * modelCoefficients[:Event]
      else
        ao.ranking = 0
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

      case ao.object_type
      when "Excursion"
        ao.ranking = ao.ranking * modelCoefficients[:Excursion]
      when "Category"
        ao.ranking = ao.ranking * modelCoefficients[:Category]
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
    # ["Actor", "Document", "Post", "Category", "Excursion", "Scormfile", "Link", "Webapp", "Comment", "Event", "Embed", "Workshop"]

    resourceAOTypes = VishConfig.getAvailableResourceModels
    #["Document", "Webapp", "Scormfile", "Link", "Embed", "Writing", "Excursion", "Workshop"]

    resourceAOs = ActivityObject.where("object_type in (?)", resourceAOTypes)
    userAOs = ActivityObject.joins(:actor).where("activity_objects.object_type='Actor' and actors.subject_type='User'")
    eventAOs = ActivityObject.where("object_type in (?)", ["Event"])
    categoryAOs = ActivityObject.where("object_type in (?)", ["Category"])

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
    nonDownloableResources = ["Link", "Embed", "Workshop"]
    linkWeights = {}
    linkWeights[:fVisits] = 0.4
    linkWeights[:fDownloads] = 0
    linkWeights[:fLikes] = 0.6
    
    #Get values to normalize scores
    resource_maxVisitCount = [resourceAOs.maximum(:visit_count),1].max
    resource_maxDownloadCount = [resourceAOs.maximum(:download_count),1].max
    resource_maxLikeCount = [resourceAOs.maximum(:like_count),1].max

    resourceAOs.each do |ao|
      if ao.updated_at.nil?
        ao.popularity = 0
        next
      end

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


    ###################################
    ###Step 4. Categories popularity
    ###################################
    puts "Recalculating categories popularity"

    categoryWeights = {}
    categoryWeights[:fVisits] = 1

    #Get values to normalize scores
    categories_maxVisitCount = [categoryAOs.maximum(:visit_count),1].max

    categoryAOs.each do |ao|
      timeWindow = [(Time.now - ao.updated_at)/windowLength.to_f,0.5].max
      fVisits = (ao.visit_count/timeWindow.to_f)/categories_maxVisitCount

      ao.popularity = ((categoryWeights[:fVisits] * fVisits)*metricsScaleFactor).round(0)
    end

    ##############
    # Fit scores to the [0,1] scale [Excursion with highest popularity will have a popularity of 1]
    # Transform [0,1] to [0,metricsScaleFactor] scale
    # Apply coefficients to give some models more importance than others
    ##############
    puts "Fitting scores and applying correction coefficients"

    modelCoefficients = {}
    modelCoefficients[:Excursion] = 1
    modelCoefficients[:Resource] = 0.9
    modelCoefficients[:User] = 0.8
    modelCoefficients[:Event] = 0.1
    modelCoefficients[:Category] = 0.8
    
    maxPopularityForResources = [resourceAOs.max_by {|ao| ao.popularity }.popularity,1].max
    maxPopularityForUsers = [userAOs.max_by {|ao| ao.popularity }.popularity,1].max
    maxPopularityForEvents = [eventAOs.max_by {|ao| ao.popularity }.popularity,1].max
    maxPopularityForCategories = [categoryAOs.max_by {|ao| ao.popularity }.popularity,1].max

    resourcesCoefficient = (1*metricsScaleFactor)/maxPopularityForResources.to_f
    usersCoefficient = (1*metricsScaleFactor)/maxPopularityForUsers.to_f
    eventsCoefficient = (1*metricsScaleFactor)/maxPopularityForEvents.to_f
    categoriesCoefficient = (1*metricsScaleFactor)/maxPopularityForCategories.to_f

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

    categoryAOs.each do |ao|
      ao.popularity = ao.popularity * categoriesCoefficient * modelCoefficients[:Category]
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

  #Usage
  #Development:   bundle exec rake scheduled:deleteExpiredTokens
  #In production: bundle exec rake scheduled:deleteExpiredTokens RAILS_ENV=production
  task :deleteExpiredTokens => :environment do
    puts "Deleting expired tokens"
    WappAuthToken.deleteExpiredTokens
    puts "Task finished"
  end

  #Usage
  #Development: bundle exec rake scheduled:updateWordsFrequency
  #Production: bundle exec rake scheduled:updateWordsFrequency RAILS_ENV=production
  task :updateWordsFrequency => :environment do |t, args|
    puts "Updating Words Frequency (for calculating TF-IDF)"

    #1. Remove previous metadata records
    Word.destroy_all

    #2. Retrieve words from LO metadata
    ActivityObject.getAllPublicResources.each do |lo|
      processText(lo.title)
      processText(lo.description)
      processText(lo.tag_list.join(""))
    end

    #3. Add stopwords
    # For stopwords, the occurences of the word record is set to the 'Vish::Application::config.repository_total_entries' value.
    # This way, the IDF for this word will be 0, and therefore the TF-IDF will be 0 too. This way, the word is ignored when calcuting the TF-IDF.
    Vish::Application::config.stopwords.each do |stopword|
      wordRecord = Word.find_by_value(stopword)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = stopword
      end
      wordRecord.occurrences = Vish::Application::config.repository_total_entries
      wordRecord.save!
    end
  end

  def processText(text)
    return if text.blank? or !text.is_a? String
    RecommenderSystem.processFreeText(text).each do |word,occurrences|
      wordRecord = Word.find_by_value(word)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = word
      end
      wordRecord.occurrences += occurrences
      wordRecord.save! rescue nil #This can be raised for too long words (e.g. long urls)
    end
  end

end
