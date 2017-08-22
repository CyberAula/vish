# encoding: utf-8
TRS_FILE_PATH = "reports/trsystem.txt"

namespace :trsystem do

  task :prepare do
    require "#{Rails.root}/lib/task_utils"
    prepareFile(TRS_FILE_PATH)
    writeInTRS("Tracking System Report")
  end

  def writeInTRS(line)
    write(line,TRS_FILE_PATH)
  end

  #Remove entries from bots.
  #Usage
  #Development:   bundle exec rake trsystem:removeBotEntries
  #In production: bundle exec rake trsystem:removeBotEntries RAILS_ENV=production
  task :removeBotEntries, [:prepare] => :environment do |t,args|
    printTitle("Removing bot entries")

    entriesDestroyed = 0

    ActiveRecord::Base.uncached do
      TrackingSystemEntry.find_each batch_size: 1000 do |e|
        if TrackingSystemEntry.isUserAgentBot?(e.user_agent)
          e.delete
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
    Rake::Task["trsystem:prepare"].invoke if args.prepare

    writeInTRS("")
    writeInTRS("Populating related excursions")
    writeInTRS("")

    ActiveRecord::Base.uncached do
      TrackingSystemEntry.where(:app_id=>"ViSH Viewer", :related_entity_id => nil).find_each batch_size: 1000 do |e|
        begin
          d = JSON(e["data"]) rescue {}
          unless d.blank? or d["lo"].nil? or d["lo"]["id"].nil?
            entityId = (d["lo"]["id"]).to_i rescue nil
            e.update_column :related_entity_id, entityId unless entityId.nil?
          end
        rescue Exception => e
          puts "Exception: " + e.message
        end
      end

      #Remove bad entries
      TrackingSystemEntry.where(:app_id=>"ViSH Viewer", :related_entity_id => nil).find_each batch_size: 1000 do |e|
        e.delete
      end
    end

    writeInTRS("Task finished")
  end

  #Check entries of excursions
  #  Delete non useful tracking system entries of excursions
  #  Lighten stored data
  #Usage
  #Development:   bundle exec rake trsystem:checkEntriesOfExcursions
  task :checkEntriesOfExcursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["trsystem:prepare"].invoke if args.prepare

    writeInTRS("")
    writeInTRS("Checking tracking system entries of excursions")
    writeInTRS("")

    ActiveRecord::Base.uncached do
      vvEntries = TrackingSystemEntry.where("app_id='ViSH Viewer' and related_entity_id is NOT NULL and checked='false'")
      vvEntries.find_each batch_size: 1000 do |e|
        if LoInteraction.isValidTSEntry?(e)
          e.update_column :checked, true

          #Lighten stored data
          d = JSON.parse(e.data)
          d.delete "device"
          d.delete "rs"
          d["lo"]["nSlides"] = d["lo"]["content"]["slides"].values.length rescue nil
          d["lo"].delete "content"

          e.update_column :data, d.to_json
        else
          e.delete
        end
      end
    end

    writeInTRS("Task finished")
  end

  #Delete tracking system entries of removed excursions
  #Usage
  #Development:   bundle exec rake trsystem:deleteEntriesOfRemovedExcursions
  task :deleteEntriesOfRemovedExcursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["trsystem:prepare"].invoke if args.prepare

    writeInTRS("")
    writeInTRS("Deleting tracking system entries of excursions that have been removed")
    writeInTRS("")

    ActiveRecord::Base.uncached do
      eIds = Excursion.pluck(:id)
      vvEntries = TrackingSystemEntry.where("app_id='ViSH Viewer' and related_entity_id not in (?)", eIds)
      vvEntries.find_each batch_size: 1000 do |e|
        e.delete
      end
      #Delete LOInteractions from removed excursions
      LoInteraction.all.select{|l| l.activity_object.nil?}.each do |loi|
        loi.destroy
      end
    end

    writeInTRS("Task finished")
  end

  #Limit the number of entries that are stored for each excursion
  #Save the last N entries for each excursion
  #Usage
  #Development:   bundle exec rake trsystem:limitEntriesOfExcursions
  task :limitEntriesOfExcursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["trsystem:prepare"].invoke if args.prepare

    writeInTRS("")
    writeInTRS("Limiting stored tracking system entries of excursions")
    writeInTRS("")

    n = (Vish::Application.config.APP_CONFIG["tracking_system"] and Vish::Application.config.APP_CONFIG["tracking_system"]["max_interactions_per_lo"].is_a? Integer) ? Vish::Application.config.APP_CONFIG["tracking_system"]["max_interactions_per_lo"] : 2000

    unless n < 0
      ActiveRecord::Base.uncached do
        Excursion.pluck(:id).each do |eId|
          vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer", :checked => true, :related_entity_id => eId)
          if vvEntries.count > n
            ids = vvEntries.limit(n).order("created_at DESC").pluck(:id)
            vvEntries.where("id not in (?)", ids).find_each batch_size: 1000 do |e|
              e.delete
            end
          end
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

    writeInTRS("Calculating interaction values")

    ActiveRecord::Base.uncached do
      excursions = Excursion.where("draft='false'")
      vvEntries = TrackingSystemEntry.where("app_id='ViSH Viewer' and related_entity_id is NOT NULL and checked='true'")

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
            if LoInteraction.isValidCheckedInteraction?(d)
              loInteraction.nvalidsamples += 1

              #Aux vars
              totalDuration = d["duration"].to_i

              isSignificativeInteraction = LoInteraction.isSignificativeCheckedInteraction?(d)
              if isSignificativeInteraction
                loInteraction.nsamples += 1

                #Aux vars
                actions = d["chronology"].values.map{|v| v["actions"]}.compact.map{|v| v.values}.flatten
                nSlides = d["lo"]["nSlides"]
                cValues = d["chronology"].map{|k,v| v}
                viewedSlides = []

                loInteraction.tlo += totalDuration

                tloslide = totalDuration/nSlides
                loInteraction.tloslide += tloslide

                tloslide_min = totalDuration + 1
                tloslide_max = 0
                nSlides.times do |i|
                  tSlide = cValues.select{|v| v["slideNumber"]===(i+1).to_s}.map{|v| v["duration"].to_f}.sum.ceil.to_i
                  tloslide_min = tSlide if tSlide < tloslide_min
                  tloslide_max = tSlide if tSlide > tloslide_max
                  viewedSlides.push(i+1) if tSlide > 5
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
          loFavorites = (ex.activities.select{|a| a.activity_verb.name==="like"}.length) rescue 0
          loInteraction.favrate = (loFavorites/uniqUsers.to_f * 100).ceil.to_i rescue 0
        end

        unless loInteraction.nvalidsamples<1
          loInteraction.acceptancerate = (users_accept/(users_accept+users_reject).to_f * 100).ceil.to_i rescue 0
        end

        loInteraction.save! if loInteraction.nsamples>0
      end
    end

    writeInTRS("Task finished")
  end

end