# encoding: utf-8

namespace :scheduled do

  #Usage
  #Development:   bundle exec rake scheduled:regenerateSitemap
  #In production: bundle exec rake scheduled:regenerateSitemap RAILS_ENV=production
  task :regenerateSitemap => :environment do
    Rake::Task["sitemap:refresh"].invoke("-s")
  end

  #Usage
  #Development:   bundle exec rake scheduled:recalculateRankingMetrics
  #In production: bundle exec rake scheduled:recalculateRankingMetrics RAILS_ENV=production
  task :recalculateRankingMetrics => :environment do
    puts "Recalculating ranking metrics"
    timeStart = Time.now

    #1. Recalculate popularity scores
    Rake::Task["scheduled:recalculatePopularity"].invoke

    #2. Recalculate ranking metrics scores
    puts "Recalculating ranking values"

    metricsParams = Vish::Application::config.metrics_default_ranking
    modelCoefficients = {}
    modelCoefficients[:Excursion] = metricsParams[:coefficients][:excursion] || 1
    modelCoefficients[:Resource] = metricsParams[:coefficients][:resource] || 1
    modelCoefficients[:User] = metricsParams[:coefficients][:user] || 1
    modelCoefficients[:Event] = metricsParams[:coefficients][:event] || 1
    modelCoefficients[:Category] = metricsParams[:coefficients][:category] || 1
    
    #Since Sphinx does not support signed integers, we have to store the ranking metrics scores in a positive scale.
    #ao.popularity is in a scale [0,1000000]
    #ao.qscore is in a scale [0,1000000]
    #ao.ranking will be in a scale [0,1000000]
    #We will take into account qscore only for resources (and categories). 
    #For non resource aos, ranking scores will be calculated based on popularity

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
    resourceRankingWeights[:popularity] = metricsParams[:w_popularity]
    resourceRankingWeights[:qscore] = metricsParams[:w_qscore]

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

    #3. Fit ranking metrics scores
    #Needed to compare different models using the ranking metrics scores
    #Popularity scores have been corrected in the recalculate popularity method.
    puts "Fitting scores and applying correction coefficients"

    unless resourceAOs.blank?
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

    metricsParams = Vish::Application::config.metrics_popularity

    # This task recalculates popularity scores in Activity Objects
    # Object types of Activity Objects:
    # ["Actor", "Document", "Post", "Category", "Excursion", "Scormfile", "Link", "Webapp", "Comment", "Event", "Embed", "Workshop"]
    resourceAOTypes = VishConfig.getAvailableResourceModels
    #["Document", "Webapp", "Scormfile", "Link", "Embed", "Writing", "Excursion", "Workshop"]
    resourceAOs = ActivityObject.where("object_type in (?)", resourceAOTypes)
    userAOs = ActivityObject.joins(:actor).where("activity_objects.object_type='Actor' and actors.subject_type='User'")
    eventAOs = ActivityObject.where("object_type in (?)", ["Event"])
    categoryAOs = ActivityObject.where("object_type in (?)", ["Category"])

    windowLength = 2592000 #1 month
    #Change windowLength according to settings
    windowLength = windowLength * metricsParams[:timeWindowLength]

    #Popularity is calculated in a 0-1 scale.
    #We have to convert it to an integer.
    # metricsScaleFactor = 1000000 will store 6 significative numbers
    metricsScaleFactor = 1000000

    #################################
    #First. Resource popularity
    #################################
    puts "Recalculating resources popularity"

    #Weights for downloadable resources
    resourceWeights = {}
    resourceWeights[:fVisits] = metricsParams[:resources][:w_fVisits]
    resourceWeights[:fLikes] = metricsParams[:resources][:w_fLikes]
    resourceWeights[:fDownloads] = metricsParams[:resources][:w_fDownloads]

    #Specify different weights for resources that can't be downloaded:
    nonDownloableResources = ["Link", "Embed", "Workshop"]
    linkWeights = {}
    linkWeights[:fVisits] = metricsParams[:non_downloadable_resources][:w_fVisits]
    linkWeights[:fLikes] = metricsParams[:non_downloadable_resources][:w_fLikes]
    linkWeights[:fDownloads] = 0
    
    unless resourceAOs.blank?
      #Get maximum values to normalize scores
      maxfVisits = 1
      maxfDownloads = 1
      maxfLikes = 1
      resourceAOs.map{ |ao|
        timeWindow = [(Time.now - ao.created_at)/windowLength.to_f,0.5].max
        fVisits = (ao.visit_count/timeWindow.to_f)
        fDownloads = (ao.download_count/timeWindow.to_f)
        fLikes = (ao.like_count/timeWindow.to_f)
        maxfVisits = fVisits if fVisits > maxfVisits
        maxfDownloads = fDownloads if fDownloads > maxfDownloads
        maxfLikes = fLikes if fLikes > maxfLikes
      }

      #calculate popularity scores
      resourceAOs.each do |ao|
        if ao.created_at.nil?
          ao.popularity = 0
          next
        end

        timeWindow = [(Time.now - ao.created_at)/windowLength.to_f,0.5].max
        fVisits = (ao.visit_count/timeWindow.to_f)/maxfVisits
        fDownloads = (ao.download_count/timeWindow.to_f)/maxfDownloads
        fLikes = (ao.like_count/timeWindow.to_f)/maxfLikes

        if(nonDownloableResources.include? ao.object_type)
          rWeights = linkWeights
        else
          rWeights = resourceWeights
        end

        ao.popularity = ((rWeights[:fVisits] * fVisits + rWeights[:fDownloads] * fDownloads + rWeights[:fLikes] * fLikes)*metricsScaleFactor).round(0)
      end
    end

    ###################################
    ###Step 2. Users popularity
    ###################################
    puts "Recalculating users popularity"

    userWeights = {}
    userWeights[:followerCount] = metricsParams[:users][:w_followers]
    userWeights[:resourcesPopularity] = metricsParams[:users][:w_resources]

    unless userAOs.blank?
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
    end

    ###################################
    ###Step 3. Events popularity
    ###################################
    puts "Recalculating events popularity"

    eventWeights = {}
    eventWeights[:fVisits] = metricsParams[:events][:w_fVisits]
    eventWeights[:fLikes] = metricsParams[:events][:w_fLikes]

    unless eventAOs.blank?
      #Get maximum values to normalize scores
      events_maxfVisits = 1
      events_maxfLikes = 1

      eventAOs.map{ |ao|
        timeWindow = [(Time.now - ao.created_at)/windowLength.to_f,0.5].max
        fVisits = (ao.visit_count/timeWindow.to_f)
        fLikes = (ao.like_count/timeWindow.to_f)
        events_maxfVisits = fVisits if fVisits > events_maxfVisits
        events_maxfLikes = fLikes if fLikes > events_maxfLikes
      }

      eventAOs.each do |ao|
        if ao.created_at.nil?
          ao.popularity = 0
          next
        end

        timeWindow = [(Time.now - ao.created_at)/windowLength.to_f,0.5].max
        fVisits = (ao.visit_count/timeWindow.to_f)/events_maxfVisits
        fLikes = (ao.like_count/timeWindow.to_f)/events_maxfLikes

        ao.popularity = ((eventWeights[:fVisits] * fVisits + eventWeights[:fLikes] * fLikes)*metricsScaleFactor).round(0)
      end
    end


    ###################################
    ###Step 4. Categories popularity
    ###################################
    puts "Recalculating categories popularity"

    categoryWeights = {}
    categoryWeights[:fVisits] = 1

    unless categoryAOs.blank?
      #Get values to normalize scores
      categories_maxfVisits = 1

      categoryAOs.map{ |ao|
        timeWindow = [(Time.now - ao.created_at)/windowLength.to_f,0.5].max
        fVisits = (ao.visit_count/timeWindow.to_f)
        categories_maxfVisits = fVisits if fVisits > categories_maxfVisits
      }

      categoryAOs.each do |ao|
        if ao.created_at.nil?
          ao.popularity = 0
          next
        end
        
        timeWindow = [(Time.now - ao.created_at)/windowLength.to_f,0.5].max
        fVisits = (ao.visit_count/timeWindow.to_f)/categories_maxfVisits

        ao.popularity = ((categoryWeights[:fVisits] * fVisits)*metricsScaleFactor).round(0)
      end
    end

    ##############
    # Fit scores to the [0,1] scale (e.g. those resources with highest popularity will have a popularity of 1)
    # Transform [0,1] to [0,metricsScaleFactor] scale
    # Apply coefficients (if specify in the settings) to give some models more importance than others
    ##############
    puts "Fitting scores and applying correction coefficients"

    maxPopularityForResources = [resourceAOs.max_by {|ao| ao.popularity }.popularity,1].max unless resourceAOs.blank?
    maxPopularityForUsers = [userAOs.max_by {|ao| ao.popularity }.popularity,1].max unless userAOs.blank?
    maxPopularityForEvents = [eventAOs.max_by {|ao| ao.popularity }.popularity,1].max unless eventAOs.blank?
    maxPopularityForCategories = [categoryAOs.max_by {|ao| ao.popularity }.popularity,1].max unless categoryAOs.blank?

    resourcesCoefficient = (1*metricsScaleFactor)/maxPopularityForResources.to_f unless resourceAOs.blank?
    usersCoefficient = (1*metricsScaleFactor)/maxPopularityForUsers.to_f unless userAOs.blank?
    eventsCoefficient = (1*metricsScaleFactor)/maxPopularityForEvents.to_f unless eventAOs.blank?
    categoriesCoefficient = (1*metricsScaleFactor)/maxPopularityForCategories.to_f unless categoryAOs.blank?

    modelCoefficients = {}
    modelCoefficients[:Excursion] = metricsParams[:coefficients][:excursion] || 1
    modelCoefficients[:Resource] = metricsParams[:coefficients][:resource] || 1
    modelCoefficients[:User] = metricsParams[:coefficients][:user] || 1
    modelCoefficients[:Event] = metricsParams[:coefficients][:event] || 1
    modelCoefficients[:Category] = metricsParams[:coefficients][:category] || 1

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
      processResourceText((lo.title||"")+(lo.description||""))
    end

    #3. Add stopwords
    # For stopwords, the occurences of the word record is set to the 'Vish::Application::config.rs_repository_total_entries' value.
    # This way, the IDF value for these words will be close to 0, and therefore the TF-IDF value will be close to 0 too.
    # Stop words are readed from the file stopwords.yml
    stopwords = File.read("config/stopwords.yml").split(",").map{|s| s.gsub("\n","").gsub("\"","") } rescue []
    stopwords.each do |stopword|
      wordRecord = Word.find_by_value(stopword)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = stopword
      end
      wordRecord.occurrences = Vish::Application::config.rs_repository_total_entries
      wordRecord.save!
    end
    
    puts "Task finished"
  end

  def processResourceText(text)
    return if text.blank? or !text.is_a? String
    RecommenderSystem.processFreeText(text).each do |word,occurrences|
      wordRecord = Word.find_by_value(word)
      if wordRecord.nil?
        wordRecord = Word.new
        wordRecord.value = word
      end
      wordRecord.occurrences += 1
      wordRecord.save! rescue nil #This can be raised for too long words (e.g. long urls)
    end
  end

  #Usage
  #Development: bundle exec rake scheduled:updateInteractions
  #Production: bundle exec rake scheduled:updateInteractions RAILS_ENV=production
  task :updateInteractions => :environment do |t, args|
    puts "Updating Interactions"
    
    Rake::Task["trsystem:populateRelatedExcursions"].invoke
    Rake::Task["trsystem:deleteNonValidEntriesForLoInteractions"].invoke
    Rake::Task["trsystem:calculateInteractionValues"].invoke

    #Send excursions with interactions to LOEP
    unless Vish::Application.config.APP_CONFIG['loep'].nil?
      aos = LoInteraction.all.map{|i| i.activity_object}.select{|ao| !ao.nil? and ao.object_type == "Excursion" and ao.scope==0}
      VishLoep.sendActivityObjects(aos,{:sync=>true,:trace=>true})
    end

    puts "Task finished"
  end

end