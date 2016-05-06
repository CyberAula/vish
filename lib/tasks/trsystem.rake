# encoding: utf-8
TRS_FILE_PATH = "reports/trsystem.txt"

namespace :trsystem do

  #Usage
  #Development:   bundle exec rake trsystem:all
  #In production: bundle exec rake trsystem:all RAILS_ENV=production
  task :all => :environment do
    Rake::Task["trsystem:prepare"].invoke
    Rake::Task["trsystem:usage"].invoke(false)
    Rake::Task["trsystem:rs"].invoke(false)
    Rake::Task["trsystem:rsViSH"].invoke(false)
  end

  task :prepare do
    require "#{Rails.root}/lib/task_utils"
    prepareFile(TRS_FILE_PATH)
    writeInTRS("Tracking System Report")
  end

  task :usage, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Usage Report")
    writeInTRS("")

    vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer")

    #Time period
    #Entries of the last 3 months
    # endDate = Time.now
    # startDate = endDate.advance(:months => -3)
    # vvEntries = vvEntries.where(:created_at => startDate..endDate)

    totalSamples = 0
    totalSlides = 0
    totalDuration = 0

    vvEntries.each do |e|
      # begin
        d = JSON(e["data"]) rescue {}

        unless d["chronology"].nil? or d["duration"].nil?
          # chronologyEntries = d["chronology"].values
          nSlides = d["chronology"].values.map{|c| c["slideNumber"]}.uniq.length
          # tDuration = chronologyEntries.map{|c| c["duration"].to_f}.sum
          tDuration = d["duration"].to_f

          #Filter extremely long and short durations
          MAX_DURATION = 1.5*60*60 #1.5 hours
          MIN_DURATION = 10 #10 secs

          if nSlides.is_a? Integer and tDuration.is_a? Float and nSlides>0 and tDuration>MIN_DURATION and tDuration<MAX_DURATION
            totalSlides += nSlides
            totalDuration += tDuration
            totalSamples += 1
          end
        end
      # rescue
      # end
    end

    writeInTRS("Total samples")
    writeInTRS(totalSamples)
    writeInTRS("Average time per slide:")
    if totalDuration > 0
      writeInTRS((totalDuration/totalSlides.to_f).round(2).to_s + " (s)")
    else
      writeInTRS("0 (s)")
    end

  end

  #Recommender System Analytics. ViSH Viewer data.
  #Usage
  #Development:   bundle exec rake trsystem:rs
  #In production: bundle exec rake trsystem:rs RAILS_ENV=production
  task :rs, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Recommender System Report. ViSH Viewer data")
    writeInTRS("")

    vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer")

    recTSD = {}

    recTSD["Random"] = {}
    recTSD["Random"]["totalRec"] = 0
    recTSD["Random"]["totalRecShow"] = 0
    recTSD["Random"]["totalRecAccepted"] = 0
    recTSD["Random"]["totalRecDenied"] = 0
    recTSD["Random"]["timeToAccept"] = []

    recTSD["ViSHRecommenderSystem"] = {}
    recTSD["ViSHRecommenderSystem"]["totalRec"] = 0
    recTSD["ViSHRecommenderSystem"]["totalRecShow"] = 0
    recTSD["ViSHRecommenderSystem"]["totalRecAccepted"] = 0
    recTSD["ViSHRecommenderSystem"]["totalRecDenied"] = 0
    recTSD["ViSHRecommenderSystem"]["timeToAccept"] = []

    #Compare Accepted group vs Denied group
    recTSD["ViSHRecommenderSystem"]["accepted"] = []
    recTSD["ViSHRecommenderSystem"]["denied"] = []


    vvEntries.each do |e|
      d = JSON(e["data"]) rescue {}
      recData = d["rs"]
      unless recData.nil? or !recData["tdata"].is_a? Hash
        firstItem = recData["tdata"].values.first
        rsItemTrackingData = JSON(firstItem["recommender_data"]) rescue nil
        unless rsItemTrackingData.nil? or !["Random","ViSHRecommenderSystem"].include? rsItemTrackingData["rec"]
          thisRecTSD = recTSD[rsItemTrackingData["rec"]]
          thisRecTSD["totalRec"] += 1

          if recData["shown"]=="true" || recData["shown"]==true
            thisRecTSD["totalRecShow"] += 1
          end

          if recData["accepted"] == "false" or recData["accepted"]==false
            thisRecTSD["totalRecDenied"] += 1
          elsif recData["accepted"] == "undefined"
            #Do nothing
          elsif recData["accepted"].is_a? String
            thisRecTSD["totalRecAccepted"] += 1

            #When accepted, measure time.
            allActions = d["chronology"].values.map{|c| c["actions"].values}.flatten rescue []
            onShowRecommendationAction = allActions.select{|a| a["id"]=="onShowRecommendations" }.last
            onAcceptRecommendationAction = allActions.select{|a| a["id"]=="onAcceptRecommendation" }.last

            if !onShowRecommendationAction.nil? and !onAcceptRecommendationAction.nil? and !onShowRecommendationAction["t"].nil? and !onAcceptRecommendationAction["t"].nil?
              recTime = (onAcceptRecommendationAction["t"].to_f - onShowRecommendationAction["t"].to_f).round(2)
              if recTime > 0
                thisRecTSD["timeToAccept"].push(recTime)
              end
            end

            #When accepted, and RS is ViSHRecommender, store accepted and denied items
            if rsItemTrackingData["rec"] == "ViSHRecommenderSystem"
              acceptedItem = recData["tdata"].values.select{|item| item["id"]==recData["accepted"]}[0]
              recTSD["ViSHRecommenderSystem"]["accepted"].push(acceptedItem)
              deniedItems = recData["tdata"].values.select{|item| item["id"]!=recData["accepted"]}
              recTSD["ViSHRecommenderSystem"]["denied"] += deniedItems
            end
          end
        end
      end
    end


    ###############
    # ViSH Recommender System vs Random vs Other recommender approaches
    ###############

    if recTSD["Random"]["timeToAccept"].length > 0
      randomAverageTimeToAccept = (recTSD["Random"]["timeToAccept"].sum/recTSD["Random"]["timeToAccept"].size.to_f).round(2)
    else
      randomAverageTimeToAccept = 0
    end

    if recTSD["ViSHRecommenderSystem"]["timeToAccept"].length > 0
      vishRSAverageTimeToAccept = (recTSD["ViSHRecommenderSystem"]["timeToAccept"].sum/recTSD["ViSHRecommenderSystem"]["timeToAccept"].size.to_f).round(2)
    else
      vishRSAverageTimeToAccept = 0
    end

    writeInTRS("")
    writeInTRS("Recommender System: Random")
    writeInTRS("Showed Recommendations:")
    writeInTRS(recTSD["Random"]["totalRecShow"])
    writeInTRS("Accepted Recommendations:")
    writeInTRS(recTSD["Random"]["totalRecAccepted"])
    writeInTRS("Denied Recommendations:")
    writeInTRS(recTSD["Random"]["totalRecDenied"])
    writeInTRS("Average time to accept a recommendation:")
    writeInTRS(randomAverageTimeToAccept)
    
    writeInTRS("")
    writeInTRS("Recommender System: ViSH Recommender")
    writeInTRS("Showed Recommendations:")
    writeInTRS(recTSD["ViSHRecommenderSystem"]["totalRecShow"])
    writeInTRS("Accepted Recommendations:")
    writeInTRS(recTSD["ViSHRecommenderSystem"]["totalRecAccepted"])
    writeInTRS("Denied Recommendations:")
    writeInTRS(recTSD["ViSHRecommenderSystem"]["totalRecDenied"])
    writeInTRS("Average time to accept a recommendation:")
    writeInTRS(vishRSAverageTimeToAccept)


    ###############
    # Accepted vs denied LOs
    ###############

    acceptedItemsLength = [1,recTSD["ViSHRecommenderSystem"]["accepted"].length].max
    deniedItemsLength = [1,recTSD["ViSHRecommenderSystem"]["denied"].length].max

    accceptedQualityScores = recTSD["ViSHRecommenderSystem"]["accepted"].map{ |i| 
      qscore = nil
      recData = JSON(i["recommender_data"]) rescue {}
      unless recData["qscore"].nil?
        qscore = recData["qscore"]
      else
        excursion = Excursion.find_by_id(i["id"])
        unless excursion.nil?
          qscore = excursion.qscore
        end
      end
      qscore
    }.compact

    deniedQualityScores = recTSD["ViSHRecommenderSystem"]["denied"].map{ |i| 
      qscore = nil
      recData = JSON(i["recommender_data"]) rescue {}
      unless recData["qscore"].nil?
        qscore = recData["qscore"]
      else
        excursion = Excursion.find_by_id(i["id"])
        unless excursion.nil?
          qscore = excursion.qscore
        end
      end
      qscore
    }.compact

    accceptedPopularityScores = recTSD["ViSHRecommenderSystem"]["accepted"].map{ |i| 
      popularity = nil
      recData = JSON(i["recommender_data"]) rescue {}
      unless recData["popularity"].nil?
        popularity = recData["popularity"]
      else
        excursion = Excursion.find_by_id(i["id"])
        unless excursion.nil?
          popularity = excursion.popularity
        end
      end
      popularity
    }.compact

    deniedPopularityScores = recTSD["ViSHRecommenderSystem"]["denied"].map{ |i| 
      popularity = nil
      recData = JSON(i["recommender_data"]) rescue {}
      unless recData["popularity"].nil?
        popularity = recData["popularity"]
      else
        excursion = Excursion.find_by_id(i["id"])
        unless excursion.nil?
          popularity = excursion.popularity
        end
      end
      popularity
    }.compact

    accceptedAverageOverallScore = (recTSD["ViSHRecommenderSystem"]["accepted"].map{|i| JSON(i["recommender_data"])["overall_score"]}.sum/acceptedItemsLength.to_f).round(4)
    deniedAverageOverallScore = (recTSD["ViSHRecommenderSystem"]["denied"].map{|i| JSON(i["recommender_data"])["overall_score"]}.sum/deniedItemsLength.to_f).round(4)

    accceptedAverageCSScore = (recTSD["ViSHRecommenderSystem"]["accepted"].map{|i| JSON(i["recommender_data"])["cs_score"]}.sum/acceptedItemsLength.to_f).round(4)
    deniedAverageCSScore = (recTSD["ViSHRecommenderSystem"]["denied"].map{|i| JSON(i["recommender_data"])["cs_score"]}.sum/deniedItemsLength.to_f).round(4)

    accceptedAverageUSScore = (recTSD["ViSHRecommenderSystem"]["accepted"].reject{|i| JSON(i["recommender_data"])["us_score"].nil?}.map{|i| JSON(i["recommender_data"])["us_score"]}.sum/acceptedItemsLength.to_f).round(4)
    deniedAverageUSScore = (recTSD["ViSHRecommenderSystem"]["denied"].reject{|i| JSON(i["recommender_data"])["us_score"].nil?}.map{|i| JSON(i["recommender_data"])["us_score"]}.sum/deniedItemsLength.to_f).round(4)

    accceptedAveragePopularityScore = ((accceptedPopularityScores.sum/([1,accceptedPopularityScores.length].max)).to_f).round(0)
    deniedAveragePopularityScore = ((deniedPopularityScores.sum/([1,deniedPopularityScores.length].max)).to_f).round(0)

    accceptedAverageQualityScore = ((accceptedQualityScores.sum/([1,accceptedQualityScores.length].max)).to_f).round(0)
    deniedAverageQualityScore = ((deniedQualityScores.sum/([1,deniedQualityScores.length].max)).to_f).round(0)

    writeInTRS("")
    writeInTRS("Group of accepted LOs")
    writeInTRS("Overall score:")
    writeInTRS(accceptedAverageOverallScore)
    writeInTRS("Content similarity score:")
    writeInTRS(accceptedAverageCSScore)
    writeInTRS("User similarity score:")
    writeInTRS(accceptedAverageUSScore)
    writeInTRS("Popularity score:")
    writeInTRS(accceptedAveragePopularityScore)
    writeInTRS("Quality score:")
    writeInTRS(accceptedAverageQualityScore)

    writeInTRS("")
    writeInTRS("Group of denied LOs")
    writeInTRS("Overall score:")
    writeInTRS(deniedAverageOverallScore)
    writeInTRS("Content similarity score:")
    writeInTRS(deniedAverageCSScore)
    writeInTRS("User similarity score:")
    writeInTRS(deniedAverageUSScore)
    writeInTRS("Popularity score:")
    writeInTRS(deniedAveragePopularityScore)
    writeInTRS("Quality score:")
    writeInTRS(deniedAverageQualityScore)
  end

  #Recommender System Analytics. ViSH data (complemented with ViSH Viewer data).
  #Usage
  #Development:   bundle exec rake trsystem:rsViSH
  #In production: bundle exec rake trsystem:rsViSH RAILS_ENV=production
  task :rsViSH, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Recommender System Report. ViSH data")
    writeInTRS("")

    vEntries = TrackingSystemEntry.where(:app_id=>"ViSH RLOsInExcursions")

    results = {}
    results["samples"] = 0
    results["rec"] = 0
    results["norec"] = 0

    vEntries.each do |e|
      d = JSON(e["data"]) rescue {}
      unless d.nil? or d["rec"].nil?
        results["samples"] += 1
        if d["rec"]==false or d["rec"]=="false"
          results["norec"] += 1
        else
          results["rec"] += 1
        end
      end
    end

    #Integrate data from the VV tracker
    if vEntries.length > 0
      VVacceptedRecomendations = 0
      VVacceptedRecomendationsLoggedUsers = 0
      VVacceptedRecomendationsNonLoggedUsers = 0
      startDate = vEntries.minimum(:created_at)
      endDate = vEntries.maximum(:created_at)
      vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer", :created_at => startDate..endDate)
      vvEntries.each do |e|
        d = JSON(e["data"]) rescue {}
        userData = d["user"]
        recData = d["rs"]
        unless recData.nil? or !recData["tdata"].is_a? Hash
          firstItem = recData["tdata"].values.first
          rsItemTrackingData = JSON(firstItem["recommender_data"]) rescue nil
          unless rsItemTrackingData.nil?
            if recData["accepted"] == "false" or recData["accepted"]==false or recData["accepted"] == "undefined"
              #Do nothing
            elsif recData["accepted"].is_a? String
              if userData.nil?
                VVacceptedRecomendationsNonLoggedUsers += 1
              else
                VVacceptedRecomendationsLoggedUsers += 1
              end
              VVacceptedRecomendations += 1
            end
          end
        end
      end

      if VVacceptedRecomendations>0
        results["norec"] -= VVacceptedRecomendations
        results["rec"] += VVacceptedRecomendations
      end
    end

    writeInTRS("")
    writeInTRS("Total samples")
    writeInTRS(results["samples"])
    writeInTRS("Access by recommendation")
    writeInTRS(results["rec"])
    writeInTRS("Other access")
    writeInTRS(results["norec"])

    ###############
    # Logged vs Non Loggued users
    ###############

    results["logged"] = {}
    results["logged"]["samples"] = 0
    results["logged"]["rec"] = 0
    results["logged"]["norec"] = 0

    results["nonlogged"] = {}
    results["nonlogged"]["samples"] = 0
    results["nonlogged"]["rec"] = 0
    results["nonlogged"]["norec"] = 0

    vEntries.each do |e|
      d = JSON(e["data"]) rescue {}
      unless d.nil? or d["rec"].nil? or !d["current_subject"].is_a? String
        if d["current_subject"] == "anonymous"
          results["nonlogged"]["samples"] += 1
          if d["rec"]==false or d["rec"]=="false"
            results["nonlogged"]["norec"] += 1
          else
            results["nonlogged"]["rec"] += 1
          end
        else
          results["logged"]["samples"] += 1
          if d["rec"]==false or d["rec"]=="false"
            results["logged"]["norec"] += 1
          else
            results["logged"]["rec"] += 1
          end
        end
      end
    end

    if VVacceptedRecomendationsLoggedUsers>0
      results["logged"]["norec"] -= VVacceptedRecomendationsLoggedUsers
      results["logged"]["rec"] += VVacceptedRecomendationsLoggedUsers
    end

    if VVacceptedRecomendationsNonLoggedUsers>0
      results["nonlogged"]["norec"] -= VVacceptedRecomendationsNonLoggedUsers
      results["nonlogged"]["rec"] += VVacceptedRecomendationsNonLoggedUsers
    end

    writeInTRS("")
    writeInTRS("Loggued users")
    writeInTRS("Total samples")
    writeInTRS(results["logged"]["samples"])
    writeInTRS("Access by recommendation")
    writeInTRS(results["logged"]["rec"])
    writeInTRS("Other access")
    writeInTRS(results["logged"]["norec"])
    writeInTRS("")
    writeInTRS("Non loggued users")
    writeInTRS("Total samples")
    writeInTRS(results["nonlogged"]["samples"])
    writeInTRS("Access by recommendation")
    writeInTRS(results["nonlogged"]["rec"])
    writeInTRS("Other access")
    writeInTRS(results["nonlogged"]["norec"])

  end

  def writeInTRS(line)
    write(line,TRS_FILE_PATH)
  end


  ####################
  # Fix and filtering tasks
  ####################

  #Move user agent and user profile data from the json object to the db fields of the trackerSystemEntry entity.
  #Usage
  #Development:   bundle exec rake trsystem:addUserAgentAndUserToVVData
  #In production: bundle exec rake trsystem:addUserAgentAndUserToVVData RAILS_ENV=production
  task :addUserAgentAndUserToVVData, [:prepare] => :environment do |t,args|
    printTitle("Fixing VVData entries in the TrackingSystem")

    ActiveRecord::Base.uncached do
      vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer")
      vvEntries.find_each batch_size: 1000 do |e|
        # puts "Id: " + e.id.to_s
        d = JSON(e["data"]) rescue {}
        user_agent = d["device"]["userAgent"] rescue nil
        user_data = d["user"] rescue nil
        user_logged = !user_data.nil?

        e.update_column :user_agent, user_agent
        e.update_column :user_logged, user_logged
      end
    end

    printTitle("Task finished")
  end

  # Some manual tests
  # This should be 0:
  # TrackingSystemEntry.all.select{|e| e.user_logged and TrackingSystemEntry.isUserAgentBot?(e.user_agent)}.length

  #Remove entries from bots.
  #Usage
  #Development:   bundle exec rake trsystem:removeBotEntries
  #In production: bundle exec rake trsystem:removeBotEntries RAILS_ENV=production
  #Manual check: TrackingSystemEntry.all.select{|e| TrackingSystemEntry.isUserAgentBot?(e.user_agent)}.length
  task :removeBotEntries, [:prepare] => :environment do |t,args|
    printTitle("Removing bot entries")

    entriesDestroyed = 0

    ActiveRecord::Base.uncached do
      TrackingSystemEntry.find_each batch_size: 1000 do |e|
        if TrackingSystemEntry.isUserAgentBot?(e.user_agent)
          e.destroy
          entriesDestroyed += 1
        end
      end
    end

    printTitle(entriesDestroyed.to_s + " entries destroyed")
    printTitle("Task finished")
  end

  #List user agents.
  #Usage
  #Development:   bundle exec rake trsystem:listUAs
  #In production: bundle exec rake trsystem:listUAs RAILS_ENV=production
  task :listUAs, [:prepare] => :environment do |t,args|
    printTitle("Listing user agents")

    uaList = Hash.new
    # uaList["userAgent"] = ocurrences;

    excluded_uas = []

    ActiveRecord::Base.uncached do
      TrackingSystemEntry.find_each batch_size: 1000 do |e|
        userAgent = e.user_agent
        unless userAgent.blank? or excluded_uas.include? userAgent
          if uaList[userAgent].nil?
            uaList[userAgent] = 1
          else
            uaList[userAgent] += 1
          end
        end
      end
    end

    uaList = Hash[uaList.sort_by{|k,v| -v}]

    TRS_FILE_PATH = "reports/uas.txt"
    Rake::Task["trsystem:prepare"].invoke
    writeInTRS("User Agents Report")

    uaList.each do |userAgent,ocurrences|
      writeInTRS("Occurences: " + ocurrences.to_s  + ".  UserAgent: " + userAgent)
    end

    printTitle("Task finished")
  end


  ####################
  # LO Interactions
  ####################

  #Add index in TRSystemEntry model to quickly find entries related to specific excursions.
  #Usage
  #Development:   bundle exec rake trsystem:populateRelatedExcursions
  task :populateRelatedExcursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Populating related excursions")
    writeInTRS("")

    ActiveRecord::Base.uncached do
      vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer", :related_entity_id => nil)
      vvEntries.find_each batch_size: 1000 do |e|
        begin
          d = JSON(e["data"]) rescue {}
          unless d.blank? or d["lo"].nil? or d["lo"]["id"].nil?
            entityId = (d["lo"]["id"]).to_i rescue nil
            unless entityId.nil?
              e.update_column :related_entity_id, entityId
            end
          end
        rescue Exception => e
          puts "Exception: " + e.message
        end
      end

      #Remove bad entries
      vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer", :related_entity_id => nil)
      vvEntries.find_each batch_size: 1000 do |e|
        e.destroy
      end
    end

    writeInTRS("Task finished")
  end

  #Delete non useful tracking system entries for LO interactions
  #Usage
  #Development:   bundle exec rake trsystem:deleteNonValidEntriesForLoInteractions
  task :deleteNonValidEntriesForLoInteractions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Deleting non useful tracking system entries for LO interactions")
    writeInTRS("")

    ActiveRecord::Base.uncached do
      # nonVVEntries = TrackingSystemEntry.where("app_id!='ViSH Viewer'")
      # nonVVEntries.find_each batch_size: 1000 do |e|
      #   e.destroy
      # end
      
      vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer")
      vvEntries.find_each batch_size: 1000 do |e|
        unless LoInteraction.isValidTSEntry?(e)
          e.destroy
        end
      end
    end

    writeInTRS("Task finished")
  end

  #Get interaction values for Excursions
  #Usage
  #Development:   bundle exec rake trsystem:calculateInteractionValues
  #In production: bundle exec rake trsystem:calculateInteractionValues RAILS_ENV=production
  task :calculateInteractionValues, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["trsystem:prepare"].invoke if args.prepare
    Rake::Task["trsystem:populateRelatedExcursions"].invoke
    writeInTRS("Calculating interaction values")

    ActiveRecord::Base.uncached do
      excursions = Excursion.where("draft='false'")
      # excursions = Excursion.where("id='1143'")

      vvEntries = TrackingSystemEntry.where("app_id='ViSH Viewer' and related_entity_id is NOT NULL")

      excursions.find_each batch_size: 1000 do |ex|
        next if ex.activity_object.nil?
        exEntries = vvEntries.where("related_entity_id='"+ex.id.to_s+"'")
        next if exEntries.length<1

        loInteraction = LoInteraction.find_by_activity_object_id(ex.activity_object.id)
        if loInteraction.nil?
          loInteraction = LoInteraction.new
          loInteraction.activity_object_id = ex.activity_object.id
        end

        loInteraction.nsamples = 0
        loInteraction.nvalidsamples = 0
        
        loInteraction.tlo = 0
        loInteraction.tloslide = 0
        loInteraction.tloslide_min = 0
        loInteraction.tloslide_max = 0
        loInteraction.viewedslidesrate = 0
        loInteraction.nvisits = ex.visit_count
        loInteraction.nclicks = 0
        loInteraction.nkeys = 0
        loInteraction.naq = 0
        loInteraction.nsq = 0
        loInteraction.neq = 0
        loInteraction.acceptancerate = 0
        loInteraction.repeatrate = 0
        loInteraction.favrate = 0
        
        #Aux vars
        user_ids = []
        users_repeat_ids = []
        users_accept = 0
        users_reject = 0
        
        exEntries.find_each batch_size: 1000 do |tsentry|
          begin
            d = JSON(tsentry["data"])
            if LoInteraction.isValidInteraction?(d)
              loInteraction.nvalidsamples += 1

              #Aux vars
              totalDuration = d["duration"].to_i

              isSignificativeInteraction = LoInteraction.isSignificativeInteraction?(d)
              if isSignificativeInteraction
                loInteraction.nsamples += 1

                #Aux vars
                actions = d["chronology"].values.map{|v| v["actions"]}.compact.map{|v| v.values}.flatten
                nSlides = d["lo"]["content"]["slides"].values.length
                cValues = d["chronology"].map{|k,v| v}
                viewedSlides = []


                loInteraction.tlo += totalDuration

                tloslide = totalDuration/nSlides
                loInteraction.tloslide += tloslide

                tloslide_min = totalDuration + 1
                tloslide_max = 0
                nSlides.times do |i|
                  tSlide = cValues.select{|v| v["slideNumber"]===(i+1).to_s}.map{|v| v["duration"].to_f}.sum.ceil.to_i
                  if tSlide < tloslide_min
                    tloslide_min = tSlide
                  end
                  if tSlide > tloslide_max
                    tloslide_max = tSlide
                  end
                  if tSlide > 5
                    viewedSlides.push(i+1)
                  end
                end
                tloslide_min = [tloslide_min,totalDuration].min
                tloslide_max = [tloslide_max,totalDuration].min
                loInteraction.tloslide_min += tloslide_min
                loInteraction.tloslide_max += tloslide_max

                viewedslidesrate = (viewedSlides.length/nSlides.to_f * 100).ceil.to_i
                loInteraction.viewedslidesrate += viewedslidesrate

                clickActions = actions.select{|a| a["id"]==="click"}
                totalClicks = clickActions.length
                loInteraction.nclicks += totalClicks

                keyActions = actions.select{|a| a["id"]==="keydown"}
                totalKeys = keyActions.length
                loInteraction.nkeys += totalKeys

                answerQuizActions = actions.select{|a| a["id"]=="onAnswerQuiz"}
                answeredQuizzes = answerQuizActions.length
                #Quiz types
                multiplechoiceQuizzes = answerQuizActions.select{|a| a["params"]["type"]==="multiplechoice"}
                truefalseQuizzes = answerQuizActions.select{|a| a["params"]["type"]==="truefalse"}
                sortingQuizzes = answerQuizActions.select{|a| a["params"]["type"]==="sorting"}
                oanswerQuizzes = answerQuizActions.select{|a| a["params"]["type"]==="openAnswer" and !a["params"]["correct"].blank?}
                
                #Statements
                correctStatements = multiplechoiceQuizzes.map{|q| q["params"]["correct"]==="true" ? 1 : 0}.sum + truefalseQuizzes.map{|q| q["params"]["correctStatements"].to_i}.sum + sortingQuizzes.map{|q| q["params"]["correct"]==="true" ? 1 : 0}.sum + oanswerQuizzes.map{|q| q["params"]["correct"]==="true" ? 1 : 0}.sum
                incorrectStatements = multiplechoiceQuizzes.map{|q| q["params"]["correct"]==="false" ? 1 : 0}.sum + truefalseQuizzes.map{|q| q["params"]["incorrectStatements"].to_i}.sum + sortingQuizzes.map{|q| q["params"]["correct"]==="false" ? 1 : 0}.sum + oanswerQuizzes.map{|q| q["params"]["correct"]==="false" ? 1 : 0}.sum
                # totalStatements = (correctStatements + incorrectStatements)

                loInteraction.naq += answeredQuizzes
                loInteraction.nsq += correctStatements
                loInteraction.neq += incorrectStatements
              end

              if totalDuration > 30
                users_accept += 1
              else
                users_reject += 1
              end

              if tsentry.user_logged
                userId = d["user"]["id"]
                unless user_ids.include? userId
                  user_ids.push(userId)
                else
                  if isSignificativeInteraction
                    unless users_repeat_ids.include? userId
                      users_repeat_ids.push(userId)
                    end
                  end
                end
              end

            end
          rescue Exception => e
            puts "Exception: " + e.message
          end
        end

        #Aux vars
        uniqUsers = user_ids.uniq.length
        users_repeat = users_repeat_ids.length

        #Normalize and get final results
        unless loInteraction.nsamples<1
          loInteraction.tlo /= loInteraction.nsamples
          loInteraction.tloslide /= loInteraction.nsamples
          loInteraction.tloslide_min /= loInteraction.nsamples
          loInteraction.tloslide_max /= loInteraction.nsamples

          loInteraction.viewedslidesrate /= loInteraction.nsamples

          loInteraction.nclicks = (loInteraction.nclicks * 100)/loInteraction.nsamples
          loInteraction.nkeys = (loInteraction.nkeys * 100)/loInteraction.nsamples
          loInteraction.naq = (loInteraction.naq * 100)/loInteraction.nsamples
          loInteraction.nsq = (loInteraction.nsq * 100)/loInteraction.nsamples
          loInteraction.neq = (loInteraction.neq * 100)/loInteraction.nsamples

          loInteraction.repeatrate = (users_repeat/uniqUsers.to_f * 100).ceil.to_i rescue 0

          loFavorites = (ex.activities.select{|a| a.activity_verb.name==="like" and a.created_at > DateTime.new(2014, 12, 1, 00, 00, 0)}.length) rescue 0
          #do not use 'ex.like_count' as loFavorites, since not all favorites have been tracked
          loInteraction.favrate = (loFavorites/uniqUsers.to_f * 100).ceil.to_i rescue 0
        end

        unless loInteraction.nvalidsamples<1
          loInteraction.acceptancerate = (users_accept/(users_accept+users_reject).to_f * 100).ceil.to_i rescue 0
        end

        loInteraction.save! if loInteraction.nsamples>0
      end
    end

    # d = JSON.parse(TrackingSystemEntry.where("app_id='ViSH Viewer'").last.data)
    # actions = d["chronology"].values.map{|v| v["actions"].values}.flatten

    writeInTRS("Task finished")
  end

  #Delete tracking system entries with LO interactions with invalid values
  #Usage
  #Development:   bundle exec rake trsystem:filtertsentriesForLoInteractions
  task :filtertsentriesForLoInteractions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Filtering tracking system entries for LO interactions")
    writeInTRS("")

    destroyEntities = false #set true to remove the entities. false for tests.
    iterationsToFilter = 0

    validInteractions = LoInteraction.all.select{|it| it.nvalidsamples >= 1 and !it.activity_object.nil? and !it.activity_object.object.nil? and !it.activity_object.object.reviewers_qscore.nil?}
    # validInteractions = [Excursion.find(628).lo_interaction]
    los = validInteractions.map{|it| it.activity_object.object}

    ActiveRecord::Base.uncached do
      los.each do |lo|
        interaction = lo.lo_interaction
        vvEntries = TrackingSystemEntry.where("app_id='ViSH Viewer' and related_entity_id='"+lo.id.to_s+"'")
        vvEntries.find_each batch_size: 1000 do |e|
          #Extremely high tlo values
          d = JSON(e["data"])
          durationI = d["duration"].to_i
          actions = actions = d["chronology"].values.map{|v| v["actions"]}.compact.map{|v| v.values}.flatten
          nActions = actions.length
          actionsPer10Minutes = (nActions*10/([1,durationI/60].max).to_f).ceil
          if (durationI > (4*interaction.tlo)) and (durationI > 600) and (actionsPer10Minutes<2)
            iterationsToFilter += 1
            if destroyEntities
              e.destroy
            end
          end
        end
      end
    end

    if destroyEntities
      writeInTRS(iterationsToFilter.to_s + " iterations were deleted")
    else
      writeInTRS(iterationsToFilter.to_s + " iterations to filter were identified")
    end
    
    writeInTRS("Task finished")
  end

end
