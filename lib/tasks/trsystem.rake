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