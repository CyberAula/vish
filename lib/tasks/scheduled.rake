# encoding: utf-8

namespace :scheduled do

  #Usage
  #Development:   bundle exec rake scheduled:recalculatePopularity
  #In production: bundle exec rake scheduled:recalculatePopularity RAILS_ENV=production
	task :recalculatePopularity => :environment do
    puts "Recalculating popularity"
    timeStart = Time.now

    # This task recalculates popularity in Activity Objects
    # Object types of Activity Objects:
    # ["Actor", "Post", "Comment", "Category", "Document", "Excursion", "Link", "Event", "Embed", "Webapp", "Scormfile"]

    resourceAOs = ActivityObject.where("object_type in (?)", ["Document", "Excursion", "Webapp", "Scormfile"])
    linkAOs = ActivityObject.where("object_type in (?)", ["Link", "Embed"])
    userAOs = ActivityObject.joins(:actor).where("activity_objects.object_type='Actor' and actors.subject_type='User'")
    # eventAOs = ActivityObject.where("object_type in (?)", ["Event"])
    # categoryAOs = ActivityObject.where("object_type in (?)", ["Category"])

    windowLength = 2592000 #1 month
    #Change windowLength to 2 months
    windowLength = windowLength * 2

    #Popularity is calculated in a 0-1 scale.
    #We have to convert it to an integer.
    # popularityScaleFactor = 1000000 will store 6 significative numbers
    popularityScaleFactor = 1000000

    #################################
    #First. Resource popularity
    #################################
    puts "Recalculating resources popularity"

    resourceWeights = {}
    resourceWeights[:fVisits] = 0.25
    resourceWeights[:fdownloads] = 0.4
    resourceWeights[:fLikes] = 0.35

    #Get values to normalize scores
    resource_maxVisitCount = [resourceAOs.maximum(:visit_count),1].max
    resource_maxDownloadCount = [resourceAOs.maximum(:download_count),1].max
    resource_maxLikeCount = [resourceAOs.maximum(:like_count),1].max

    resourceAOs.each do |ao|
      timeWindow = [(Time.now - ao.updated_at)/windowLength.to_f,0.5].max
      fVisits = (ao.visit_count/timeWindow.to_f)/resource_maxVisitCount
      fDownloads = (ao.download_count/timeWindow.to_f)/resource_maxDownloadCount
      fLikes = (ao.like_count/timeWindow.to_f)/resource_maxLikeCount

      popularity = ((resourceWeights[:fVisits] * fVisits + resourceWeights[:fdownloads] * fDownloads + resourceWeights[:fLikes] * fLikes)*popularityScaleFactor).round(0)
      ao.update_column :popularity, popularity
    end

    #Link and Embeds
    #Get values to normalize scores
    linkWeights = {}
    linkWeights[:fVisits] = 0.4
    linkWeights[:fLikes] = 0.6

    links_maxVisitCount = [linkAOs.maximum(:visit_count),1].max
    links_maxLikeCount = [linkAOs.maximum(:like_count),1].max

    linkAOs.each do |ao|
      timeWindow = [(Time.now - ao.updated_at)/windowLength.to_f,0.5].max
      fVisits = (ao.visit_count/timeWindow.to_f)/resource_maxVisitCount
      fLikes = (ao.like_count/timeWindow.to_f)/resource_maxLikeCount

      popularity = ((linkWeights[:fVisits] * fVisits + linkWeights[:fLikes] * fLikes)*popularityScaleFactor).round(0)
      ao.update_column :popularity, popularity
    end

    #################################
    #Step 2. Users popularity
    #################################
    puts "Recalculating users popularity"

    userWeights = {}
    userWeights[:followerCount] = 0.4
    userWeights[:resourcesPopularity] = 0.6

    #Get values to normalize scores
    user_maxFollowerCount = [userAOs.maximum(:follower_count),1].max
    user_maxResourcesPopularity = userAOs.map{|ao| 
      Excursion.authored_by(ao.object).map{|e| e.popularity}.sum
    }.max

    userAOs.each do |ao|
      uFollowers = ao.follower_count/user_maxFollowerCount.to_f
      uResourcesPopularity = (Excursion.authored_by(ao.object).map{|e| e.popularity}.sum)/user_maxResourcesPopularity.to_f

      popularity = ((userWeights[:followerCount] * uFollowers + userWeights[:resourcesPopularity] * uResourcesPopularity)*popularityScaleFactor).round(0)
      ao.update_column :popularity, popularity
    end

    timeFinish = Time.now
    puts "Task finished"
    puts "Elapsed time: " + (timeFinish - timeStart).round(1).to_s + " (s)"
	end

end
