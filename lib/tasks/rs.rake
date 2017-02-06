# encoding: utf-8

namespace :rs do

  task :prepare do
    require "#{Rails.root}/lib/task_utils"
  end

  # Usage
  # bundle exec rake rs:utility[3.5,1]
  task :utility, [:alpha, :d] => :environment do |t, args|
    Rake::Task["rs:prepare"].invoke
    
    printTitle("Calculating Breeze's R-score utility metric")
    
    usersData = []
    breezeSettings = {:alpha => 3.5, :d => 1}.recursive_merge({:alpha=>args[:alpha], :d=>args[:d]}.parse_for_vish)
    puts "Breeze settings: " + breezeSettings.to_s

    Rsevaluation.where(:status => "Finished").each do |e|
      userData = {}
      data = JSON.parse(e.data)

      #Experiment A: recommendations taking into account user profile (e.g. home page)
      dataA = data["A"]
      userData[:scoresRecA] = dataA["recommendationsA"].map{|lo| dataA["relevances"][lo["id"]]}
      userData[:scoresRandomA] = dataA["randomA"].map{|lo| dataA["relevances"][lo["id"]]}
      userData[:breezeScoreRecA] = breeze_rscore(userData[:scoresRecA],breezeSettings)
      userData[:breezeScoreRandomA] = breeze_rscore(userData[:scoresRandomA],breezeSettings)

      #Experiment B: recommendations taking into account lo profile without user profile (e.g. non logged user seeing a resource)
      dataB = data["B"]
      userData[:scoresRecB] = dataB["recommendationsB"].map{|lo| dataB["relevances"][lo["id"]]}
      userData[:scoresRandomB] = dataB["randomB"].map{|lo| dataB["relevances"][lo["id"]]}
      userData[:breezeScoreRecB] = breeze_rscore(userData[:scoresRecB],breezeSettings)
      userData[:breezeScoreRandomB] = breeze_rscore(userData[:scoresRandomB],breezeSettings)

      usersData << userData
    end

    #Generate excel file with results
    filePath = "reports/rs_utility.xlsx"
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Recommender System Utility") do |sheet|
        rows = []
        rows << ["Recommender System Utility"]
        rowIndex = rows.length

        rows += Array.new(2 + usersData[0][:scoresRecA].length).map{|e| []}

        usersData.each_with_index do |userData,i|
          rows[rowIndex] += (["User " + (i+1).to_s] + Array.new(7))
          rows[rowIndex+1] += ["RecA","RandomA","RecB","RandomB","Breeze RecA","Breeze RandomA","Breeze RecB","Breeze RandomB"]
          userData[:scoresRecA].length.times do |j|
            rows[rowIndex+2+j] += [userData[:scoresRecA][j],userData[:scoresRandomA][j],userData[:scoresRecB][j],userData[:scoresRandomB][j]]
            rows[rowIndex+2+j] += Array.new(4) unless j==0
          end
          rows[rowIndex+2] += [userData[:breezeScoreRecA],userData[:breezeScoreRandomA],userData[:breezeScoreRecB],userData[:breezeScoreRandomB]]
        end

        rowIndex = rows.length
        rows += Array.new(13).map{|e| []}
        rows[rowIndex+1] += (["Experiment A"] + Array.new(3))
        rows[rowIndex+2] += ["Breeze Rec",nil,"Breeze Random",nil]
        rows[rowIndex+3] += ["M","SD","M","SD"]
        rows[rowIndex+4] += [DescriptiveStatistics.mean(usersData.map{|userData| userData[:breezeScoreRecA]}).round(2),DescriptiveStatistics.standard_deviation(usersData.map{|userData| userData[:breezeScoreRecA]}).round(3),DescriptiveStatistics.mean(usersData.map{|userData| userData[:breezeScoreRandomA]}).round(2),DescriptiveStatistics.standard_deviation(usersData.map{|userData| userData[:breezeScoreRandomA]}).round(3)]

        rows[rowIndex+6] += (["Experiment B"] + Array.new(3))
        rows[rowIndex+7] += ["Breeze Rec",nil,"Breeze Random",nil]
        rows[rowIndex+8] += ["M","SD","M","SD"]
        rows[rowIndex+9] += [DescriptiveStatistics.mean(usersData.map{|userData| userData[:breezeScoreRecB]}).round(2),DescriptiveStatistics.standard_deviation(usersData.map{|userData| userData[:breezeScoreRecB]}).round(3), DescriptiveStatistics.mean(usersData.map{|userData| userData[:breezeScoreRandomB]}).round(2),DescriptiveStatistics.standard_deviation(usersData.map{|userData| userData[:breezeScoreRandomB]}).round(3)]

        rows[rowIndex+10] += ["Breeze parameters"]
        rows[rowIndex+11] += ["d","Alpha"]
        rows[rowIndex+12] += [breezeSettings[:d],breezeSettings[:alpha]]

        rows.each do |row|
          sheet.add_row row
        end
      end
      prepareFile(filePath)
      p.serialize(filePath)
    end

    puts("Task Finished. Results generated at " + filePath)
  end

  # Usage
  # bundle exec rake rs:accuracy
  # Leave-one-out method: measure how often the left-out entity appears in the top N recommendations
  task :accuracy, [:random] => :environment do |t,args|
    Rake::Task["rs:prepare"].invoke

    printTitle("Calculating Accuracy using leave-one-out")
    puts "Random" if args[:random]

    #Get users with more than Nmin liked, cloned or authored resources. Restrict resources for each user to Nmax.
    Nmin = 3
    Nmax = 30
    #Specify period of the study
    endDate = DateTime.parse(Vish::Application.config.APP_CONFIG["recommender_system"][:evaluation][:endDate]) rescue DateTime.now
    startDate = DateTime.parse(Vish::Application.config.APP_CONFIG["recommender_system"][:evaluation][:startDate]) rescue (endDate - 365)
    
    likedResources = Activity.joins(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id}).where("activity_objects.object_type IN (?) and activity_objects.scope=0","Excursion").where(:created_at => startDate..endDate).group("activities.id").group_by(&:author_id)
    likedResources.map{|k,v| likedResources[k] = v.map{|a| a.direct_object}}
    authoredResources = ActivityObject.where("activity_objects.object_type IN (?) and activity_objects.scope=0","Excursion").group("activity_objects.id").group_by(&:author_id)
    authoredResources.map{|k,v| authoredResources[k] = v.map{|a| a.object}}
    
    likedAndAuthoredResources = {}
    (likedResources.keys + authoredResources.keys).uniq.each do |k|
      likedAndAuthoredResources[k] = ((likedResources[k].is_a? Array) ? likedResources[k] : [])
      lARL = likedAndAuthoredResources[k].length
      if lARL < Nmin and authoredResources[k].is_a? Array
        likedAndAuthoredResources[k] = (likedAndAuthoredResources[k] + authoredResources[k]).uniq
        lARL = likedAndAuthoredResources[k].length
      end
      likedAndAuthoredResources[k] = likedAndAuthoredResources[k].sample(Nmax)
      likedAndAuthoredResources.delete(k) if lARL < Nmin
    end

    vishFilteredActorIds = Actor.find_all_by_email(Vish::Application.config.APP_CONFIG["recommender_system"][:evaluation][:mails_filtered]).map{|a| a.id} rescue []
    likedAndAuthoredResources = likedAndAuthoredResources.select{|k,v| v.length > Nmin}.reject{|k,v| vishFilteredActorIds.include? k }
    users = Actor.find(likedAndAuthoredResources.keys)
    # users = [User.find(?).actor]

    #Recommender System settings
    rsSettings = {:preselection_filter_query => false, :preselection_filter_resource_type => false, :preselection_filter_languages => true, :preselection_filter_own_resources => false, :preselection_authored_resources => true, :preselection_size => 300, :preselection_size_min => 100, :only_context => false, :rs_weights => {:los_score=>0.6, :us_score=>0.2, :quality_score=>0.1, :popularity_score=>0.1}, :los_weights => {:title=>0.2, :description=>0.1, :language=>0.5, :keywords=>0.2}, :us_weights => {:language=>0.2, :keywords => 0.2, :los=>0.6}, :rs_filters => {:los_score=>0, :us_score=>0, :quality_score=>0.3, :popularity_score=>0}, :los_filters => {:title => 0, :description => 0, :keywords => 0, :language=>0}, :us_filters => {:language=>0, :keywords => 0, :los=>0}}

    #N values
    ns = [1,5,10,20,500]
    nMax = ns.max
    results = {}

    ns.each do |n|
      results[n.to_s] = {:attempts => 0, :successes => 0, :accuracy => 0}
    end

    users.each do |user|
      los = likedAndAuthoredResources[Actor.normalize_id(user)]
      maxUserLos = 2
      los.each do |lo|
        #Leave lo out and see if it appears on the n recommendations
        userLos = los.reject{|pastLo| pastLo.id==lo.id}
        2.times do
          unless args[:random]
            recommendations = RecommenderSystem.resource_suggestions({:n => nMax, :settings => rsSettings, :user => user, :user_settings => {}, :user_los => userLos.sample(maxUserLos), :max_user_los => maxUserLos})
          else
            recommendations = ActivityObject.getAllPublicResources.limit(nMax).order(Vish::Application::config.agnostic_random).map{|ao| ao.object}.compact
          end
          ns.each do |n|
            success = recommendations.first(n).select{|recLo| recLo.id==lo.id}.length > 0 # Success when the out entity is found on recommendations
            results[n.to_s][:attempts] += 1
            results[n.to_s][:successes] += 1 if success
          end
        end
      end
    end

    ns.each do |n|
      results[n.to_s][:accuracy] = (results[n.to_s][:successes]/results[n.to_s][:attempts].to_f * 100).round(1)
    end

    #Generate excel file with results
    filePath = "reports/rs_accuracy.xlsx"
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Recommender System Accuracy") do |sheet|
        rows = []
        rows << ["Recommender System Accuracy"]
        rows << []
        rows << ["n","accuracy","attempts","succcesses"]
        
        rows += Array.new(ns.length).map{|e| []}
        ns.each do |n|
          rows << [n,results[n.to_s][:accuracy],results[n.to_s][:attempts],results[n.to_s][:successes]]
        end

        rows.each do |row|
          sheet.add_row row
        end
      end
      prepareFile(filePath)
      p.serialize(filePath)
    end

    puts("Task Finished. Results generated at " + filePath)
  end

  # Usage
  # bundle exec rake rs:performance
  # Time taken by the recommender system to generate a set of recommendations
  task :performance => :environment do |t,args|
    Rake::Task["rs:prepare"].invoke

    printTitle("Calculating Performance")

    #Recommender System settings
    rsSettings = {:preselection_filter_query => false, :preselection_filter_resource_type => false, :preselection_filter_languages => true, :preselection_authored_resources => false, :preselection_size => 200, :preselection_size_min => 100, :only_context => true, :rs_weights => {:los_score=>0.6, :us_score=>0.2, :quality_score=>0.1, :popularity_score=>0.1}, :los_weights => {:title=>0.2, :description=>0.1, :language=>0.5, :keywords=>0.2}, :us_weights => {:language=>0.2, :keywords => 0.2, :los=>0.6}, :rs_filters => {:los_score=>0, :us_score=>0, :quality_score=>0.3, :popularity_score=>0}, :los_filters => {:title => 0, :description => 0, :keywords => 0, :language=>0}, :us_filters => {:language=>0, :keywords => 0, :los=>0}}

    #Configuration of the performance measurement task
    #Values for the preselection size
    ns = [1,50,100,500,1000,2000,5000]
    loAveragingParameter = 3000 #Ideal should be close to ActivityObject.getAllPublicResources.count
    minIterationsPerNs = 10
    maxUserLos = 1

    iterationsPerN = {}
    ns.each do |n|
      iterationsPerN[n.to_s] = [minIterationsPerNs,(loAveragingParameter/n.to_f).ceil].max
    end
    minIterationsPerN = iterationsPerN.map{|k,v| v}.min
    maxIterationsPerN = iterationsPerN.map{|k,v| v}.max

    maxPreselectionSize = Vish::Application::config.rs_max_preselection_size
    Vish::Application::config.rs_max_preselection_size = ns.max

    users = []
    los = []

    publicResources = ActivityObject.getAllPublicResources
    minIterationsPerN.times do |i|
      users << User.limit(1).registered.order(Vish::Application::config.agnostic_random).first.actor
      los << publicResources.limit(1).order(Vish::Application::config.agnostic_random).first.object
      #Perform some recommendations to get the recommender ready/'warm up'
      RecommenderSystem.resource_suggestions({:n => 20, :settings => rsSettings, :lo => los[i], :user => users[i], :user_settings => {}, :max_user_los => maxUserLos})
    end

    maxIterationsPerN.times do |i|
      users[i] = users[i%minIterationsPerN]
      los[i] = los[i%minIterationsPerN]
    end

    results = {}
    ns.each do |n|
      rsSettings = rsSettings.recursive_merge({:preselection_size => n})
      start = Time.now
      iterationsPerN[n.to_s].times do |i|
        RecommenderSystem.resource_suggestions({:n => 20, :settings => rsSettings, :lo => los[i], :user => users[i], :user_settings => {}, :max_user_los => maxUserLos})
      end
      finish = Time.now
      results[n.to_s] = {:time => ((finish - start)/iterationsPerN[n.to_s]).round(3)}
      puts n.to_s + ":" + results[n.to_s][:time].to_s + " (Elapsed time: " + (finish - start).to_s + ")"
    end

    Vish::Application::config.rs_max_preselection_size = maxPreselectionSize

    #Generate excel file with results
    filePath = "reports/rs_performance.xlsx"
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Recommender System Performance") do |sheet|
        rows = []
        rows << ["Recommender System Performance"]
        rows << []
        rows << ["n","Time"]
        
        ns.each do |n|
          rows << [n,results[n.to_s][:time]]
        end

        rows.each do |row|
          sheet.add_row row
        end
      end
      prepareFile(filePath)
      p.serialize(filePath)
    end

    puts("Task Finished. Results generated at " + filePath)
  end

  # Usage
  # bundle exec rake rs:abtesting
  # Analyze A/B testing based on ViSH Tracking Data.
  # Compare ViSH Recommender System vs Random vs Other recommendation approaches
  task :abtesting, [:n] => :environment do |t,args|
    Rake::Task["rs:prepare"].invoke
    printTitle("A/B Testing results")

    results = {}
    #Compare RS vs Random vs Other recommendation approaches
    results[:rs] =     {:n => 0, :shown => 0, :shownViSH => 0, :n2 => 0, :accepted => 0, :rejected => 0, :timesToAccept => [], :acceptedItems => [], :rejectedItems => [], :loTimesA => [], :loTimeA => {:mean => 0, :sd => 0}, :loTimesB => [], :loTimeB => {:mean => 0, :sd => 0}, :nAccessed => 0, :nGenerated => 0, :accessRatio => 0}
    results[:rsq] =    {:n => 0, :shown => 0, :shownViSH => 0, :n2 => 0, :accepted => 0, :rejected => 0, :timesToAccept => [], :acceptedItems => [], :rejectedItems => [], :loTimesA => [], :loTimeA => {:mean => 0, :sd => 0}, :loTimesB => [], :loTimeB => {:mean => 0, :sd => 0}, :nAccessed => 0, :nGenerated => 0, :accessRatio => 0}
    results[:rsqp] =   {:n => 0, :shown => 0, :shownViSH => 0, :n2 => 0, :accepted => 0, :rejected => 0, :timesToAccept => [], :acceptedItems => [], :rejectedItems => [], :loTimesA => [], :loTimeA => {:mean => 0, :sd => 0}, :loTimesB => [], :loTimeB => {:mean => 0, :sd => 0}, :nAccessed => 0, :nGenerated => 0, :accessRatio => 0}
    results[:random] = {:n => 0, :shown => 0, :shownViSH => 0, :n2 => 0, :accepted => 0, :rejected => 0, :timesToAccept => [], :acceptedItems => [], :rejectedItems => [], :loTimesA => [], :loTimeA => {:mean => 0, :sd => 0}, :loTimesB => [], :loTimeB => {:mean => 0, :sd => 0}, :nAccessed => 0, :nGenerated => 0, :accessRatio => 0}
    rsKeys = results.keys.select{|key| results[key][:n].is_a? Integer}
    
    ActiveRecord::Base.uncached do
      n = args[:n].to_i unless args[:n].nil?
      if n.is_a? Integer
        vvEntries = TrackingSystemEntry.limit(n).where(:app_id=>"ViSH Viewer").order(Vish::Application::config.agnostic_random)
        vUIEntries = TrackingSystemEntry.limit(n).where(:app_id=>"ViSHUIRecommenderSystem").order(Vish::Application::config.agnostic_random)
        vRLOsEntries = TrackingSystemEntry.limit(n).where(:app_id=>"ViSH RLOsInExcursions").order(Vish::Application::config.agnostic_random)
        sStartDate = vRLOsEntries.order("created_at ASC").first.created_at
        sEndDate = DateTime.now
      else
        vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer")
        vUIEntries = TrackingSystemEntry.where(:app_id=>"ViSHUIRecommenderSystem")
        vRLOsEntries = TrackingSystemEntry.where(:app_id=>"ViSH RLOsInExcursions")
        sStartDate = vRLOsEntries.order("created_at ASC").first.created_at
        sEndDate = (vRLOsEntries.order("created_at DESC").first.created_at + 1.day)
      end
      methodName = ((n.is_a? Integer) ? "each" : "find_each")
      methodParams = (methodName=="find_each" ? [{:batch_size => 1000}] : [])

      #[1] ViSH Editor Tracked Data
      vvEntries.send(methodName,*methodParams) do |e|
        d = JSON(e["data"]) rescue {}
        recData = d["rs"]
        next if recData.nil? or !recData["tdata"].is_a? Hash
        
        firstItem = recData["tdata"].values.first
        rsItemTrackingData = JSON(firstItem["recommender_data"]) rescue nil
        next if rsItemTrackingData.nil? or !(["ViSHRecommenderSystem","ViSHRS-Quality","ViSHRS-Quality-Popularity","Random"].include? rsItemTrackingData["rec"])
        
        case rsItemTrackingData["rec"]
        when "ViSHRecommenderSystem"
          thisRecTSD = results[:rs]
        when "ViSHRS-Quality"
          thisRecTSD = results[:rsq]
        when "ViSHRS-Quality-Popularity"
          thisRecTSD = results[:rsqp]
        when "Random"
          thisRecTSD = results[:random]
        else
        end

        thisRecTSD[:n] += 1
        if recData["shown"]=="true" or recData["shown"]==true
          thisRecTSD[:shown] += 1
          thisRecTSD[:shownViSH] += 1 if (e.created_at >= sStartDate and e.created_at <= sEndDate)
        end

        if recData["accepted"] == "false" or recData["accepted"]==false
          thisRecTSD[:rejected] += 1
        elsif recData["accepted"] == "undefined"
          #Do nothing. Either accepted or rejected.
        elsif recData["accepted"].is_a? String
          thisRecTSD[:accepted] += 1

          #When accepted, measure time spent on select recommendation.
          allActions = d["chronology"].values.map{|c| c["actions"].values}.flatten rescue []
          onShowRecommendationAction = allActions.select{|a| a["id"]=="onShowRecommendations" }.last
          onAcceptRecommendationAction = allActions.select{|a| a["id"]=="onAcceptRecommendation" }.last

          if !onShowRecommendationAction.nil? and !onAcceptRecommendationAction.nil? and !onShowRecommendationAction["t"].nil? and !onAcceptRecommendationAction["t"].nil?
            recTime = (onAcceptRecommendationAction["t"].to_f - onShowRecommendationAction["t"].to_f).round(2)
            thisRecTSD[:timesToAccept].push(recTime) if recTime > 0
          end

          #Store accepted and rejected items
          acceptedItem = recData["tdata"].values.select{|item| item["id"]==recData["accepted"]}[0]
          thisRecTSD[:acceptedItems].push(acceptedItem)
          rejectedItems = recData["tdata"].values.select{|item| item["id"]!=recData["accepted"]}
          thisRecTSD[:rejectedItems] += rejectedItems

          #Get time spent on the resource after accept the recommendation
          TrackingSystemEntry.limit(100).where(:app_id=>"ViSH RLOsInExcursions", :created_at => e.created_at..(e.created_at+5.minutes)).order("created_at ASC").each do |eViSHLo|
            dViSHLo = JSON.parse(eViSHLo.data) rescue {}
            next if dViSHLo["rsEngine"].blank? or dViSHLo["rsEngine"]!=rsItemTrackingData["rec"]
            next if acceptedItem["id"].blank? or acceptedItem["id"].to_s!=dViSHLo["excursionId"].to_s
            loEntry = TrackingSystemEntry.find_by_tracking_system_entry_id(eViSHLo.id)
            if loEntry.nil?
              thisRecTSD[:loTimesA].push(3)
              break
            end
            next if loEntry.nil? or loEntry.app_id!="ViSH Viewer"
            
            # Calculate LO time
            dLo = JSON(e["data"]) rescue {}
            next if dLo.blank? or dLo["chronology"].blank? or dLo["duration"].blank? or dLo["lo"].blank?
            thisRecTSD[:loTimesA].push(dLo["duration"].to_i)
            break
          end
        end
      end

      #Get time spent on the resources for each recommendation approach (Another way to do it)
      vvEntries.where("tracking_system_entry_id is NOT NULL").send(methodName,*methodParams) do |e|
        loEntry = e.tracking_system_entry
        next if loEntry.nil? or loEntry.app_id!="ViSH RLOsInExcursions"

        d = JSON(loEntry["data"]) rescue {}
        next if d["rec"].blank? or d["rsEngine"].blank? or !(["ViSHRecommenderSystem","ViSHRS-Quality","ViSHRS-Quality-Popularity","Random"].include? d["rsEngine"])
 
        case d["rsEngine"]
        when "ViSHRecommenderSystem"
          thisRecTSD = results[:rs]
        when "ViSHRS-Quality"
          thisRecTSD = results[:rsq]
        when "ViSHRS-Quality-Popularity"
          thisRecTSD = results[:rsqp]
        when "Random"
          thisRecTSD = results[:random]
        else
        end

        #Calculate LO time
        dLo = JSON(e["data"]) rescue {}
        next if dLo.blank? or dLo["chronology"].blank? or dLo["duration"].blank? or dLo["lo"].blank?
        thisRecTSD[:loTimesB].push(dLo["duration"].to_i)
      end

      #[2] ViSH Tracked Data
      #Get %resources accesed by recommendations with each recommender system
      vUIEntries.send(methodName,*methodParams) do |e|
        d = JSON(e["data"]) rescue {}
        next if d["rsEngine"].blank?
        next unless d["models"]==["Excursion"]

        case d["rsEngine"]
        when "ViSHRecommenderSystem"
          thisRecTSD = results[:rs]
        when "ViSHRS-Quality"
          thisRecTSD = results[:rsq]
        when "ViSHRS-Quality-Popularity"
          thisRecTSD = results[:rsqp]
        when "Random"
          thisRecTSD = results[:random]
        else
        end

        thisRecTSD[:nGenerated] += 1
      end

      #Add generations from VE Tracked Data
      rsKeys.each do |key|
        results[key][:nGenerated] += results[key][:shownViSH]
      end
      
      vRLOsEntries.send(methodName,*methodParams) do |e|
        d = JSON(e["data"]) rescue {}
        next if d["rsEngine"].blank? or d["rec"].blank?

        case d["rsEngine"]
        when "ViSHRecommenderSystem"
          thisRecTSD = results[:rs]
        when "ViSHRS-Quality"
          thisRecTSD = results[:rsq]
        when "ViSHRS-Quality-Popularity"
          thisRecTSD = results[:rsqp]
        when "Random"
          thisRecTSD = results[:random]
        else
        end

        thisRecTSD[:nAccessed] += 1
      end

    end

    rsKeys.each do |key|
      results[key][:n2] = results[key][:accepted]+results[key][:rejected]
      results[key][:acceptedp] = (results[key][:accepted]/(results[key][:accepted]+results[key][:rejected]).to_f).round(2)
      results[key][:rejectedp] = (results[key][:rejected]/(results[key][:accepted]+results[key][:rejected]).to_f).round(2)
      results[key][:timeToAccept] = {:mean => 0, :sd => 0}
      
      topTimeThreshold = [60,DescriptiveStatistics.percentile(80,results[key][:timesToAccept]) || 60].min
      results[key][:timesToAccept] = results[key][:timesToAccept].reject{|t| t>topTimeThreshold}
      results[key][:timeToAccept] = {:mean => DescriptiveStatistics.mean(results[key][:timesToAccept]).round(1), :sd => DescriptiveStatistics.standard_deviation(results[key][:timesToAccept]).round(1)} if results[key][:timesToAccept].length > 0
      
      results[key][:acceptedItemsStats] = {:n => 0, :quality => {:mean => 0, :sd => 0}, :popularity => {:mean => 0, :sd => 0}, :score => {:mean => 0, :sd => 0}, :qualities => [], :popularities => [], :scores => []}
      if results[key][:acceptedItems].length > 0
        results[key][:acceptedItems].each do |item|
          rsData = JSON.parse(item["recommender_data"]) rescue nil
          unless rsData.nil? or rsData["qscore"].nil? or rsData["popularity"].nil? or rsData["overall_score"].nil?
            results[key][:acceptedItemsStats][:n] += 1
            results[key][:acceptedItemsStats][:qualities].push((rsData["qscore"]/100000.to_f).round(2))
            results[key][:acceptedItemsStats][:popularities].push((rsData["popularity"]/100000.to_f).round(2))
            results[key][:acceptedItemsStats][:scores].push(rsData["overall_score"].round(2))
          end
        end
        if results[key][:acceptedItemsStats][:n] > 0
          results[key][:acceptedItemsStats][:quality] = {:mean =>  DescriptiveStatistics.mean(results[key][:acceptedItemsStats][:qualities]).round(2), :sd => DescriptiveStatistics.standard_deviation(results[key][:acceptedItemsStats][:qualities]).round(2)}
          results[key][:acceptedItemsStats][:popularity] = {:mean =>  DescriptiveStatistics.mean(results[key][:acceptedItemsStats][:popularities]).round(2), :sd => DescriptiveStatistics.standard_deviation(results[key][:acceptedItemsStats][:popularities]).round(2)}
          results[key][:acceptedItemsStats][:score] = {:mean =>  DescriptiveStatistics.mean(results[key][:acceptedItemsStats][:scores]).round(2), :sd => DescriptiveStatistics.standard_deviation(results[key][:acceptedItemsStats][:scores]).round(2)}
        end
      end

      topTimeThresholdLoTimesA = [3*60*60,DescriptiveStatistics.percentile(80,results[key][:loTimesA]) || (3*60*60)].min
      results[key][:loTimesA] = results[key][:loTimesA].reject{|t| t>topTimeThresholdLoTimesA}
      results[key][:loTimeA] = {:mean => DescriptiveStatistics.mean(results[key][:loTimesA]).round(1), :sd => DescriptiveStatistics.standard_deviation(results[key][:loTimesA]).round(1)} if results[key][:loTimesA].length > 0
      topTimeThresholdLoTimesB = [3*60*60,DescriptiveStatistics.percentile(80,results[key][:loTimesB]) || (3*60*60)].min
      results[key][:loTimesB] = results[key][:loTimesB].reject{|t| t>topTimeThresholdLoTimesB}
      results[key][:loTimeB] = {:mean => DescriptiveStatistics.mean(results[key][:loTimesB]).round(1), :sd => DescriptiveStatistics.standard_deviation(results[key][:loTimesB]).round(1)} if results[key][:loTimesB].length > 0
    
      if results[key][:nGenerated] > 0
        results[key][:accessRatio] = (results[key][:nAccessed]/results[key][:nGenerated].to_f).round(3)
      end
    end

    #Print main results
    rsKeys.each do |key|
      puts "\nResults for: " + key.to_s
      resultToPrint = results[key].select{|k,v| v.is_a? String or v.is_a? Integer or v.is_a? Float or [:acceptedItemsStats,:loTimeA,:loTimeB].include? k}.recursive_merge({})
      resultToPrint[:acceptedItemsStats] = resultToPrint[:acceptedItemsStats].select{|k,v| v.is_a? String or v.is_a? Integer or v.is_a? Float or [:quality, :popularity, :score].include? k}
      puts resultToPrint.to_s
    end
    puts "\n"

    #Generate excel file with results
    filePath = "reports/rs_abtesting.xlsx"
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "AB Testing Acceptance") do |sheet|
        rows = []
        rows << ["Recommender System A/B Testing: Acceptance"]
        
        rsKeys.each do |key|
          2.times do |i|
            rows << []
          end
          rows << [key.to_s]
          rows << ["n","Shown","ShownViSH","n2 (Accepted or Rejected)","Accepted","Accepted (%)","Rejected", "Rejected (%)","Time (M)","Time (SD)","Accessed","Generated","AccessRatio"]
          rows << [results[key][:n],results[key][:shown],results[key][:shownViSH],results[key][:n2],results[key][:accepted],results[key][:acceptedp],results[key][:rejected],results[key][:rejectedp],results[key][:timeToAccept][:mean],results[key][:timeToAccept][:sd],results[key][:nAccessed],results[key][:nGenerated],results[key][:accessRatio]]
        end

        3.times do |i|
          rows << []
        end

        rows << ["Recommender System A/B Testing: Items"]
        rsKeys.each do |key|
          2.times do |i|
            rows << []
          end
          rows << [key.to_s]
          rows << ["n","quality","","popularity","","score","","qualities","popularities","scores"]
          rows << ["","M","SD","M","SD","M","SD"]
          rows << [results[key][:acceptedItemsStats][:n],results[key][:acceptedItemsStats][:quality][:mean],results[key][:acceptedItemsStats][:quality][:sd],results[key][:acceptedItemsStats][:popularity][:mean],results[key][:acceptedItemsStats][:popularity][:sd],results[key][:acceptedItemsStats][:score][:mean],results[key][:acceptedItemsStats][:score][:sd]]
          results[key][:acceptedItemsStats][:qualities].length.times do |j|
            rows << ["","","","","","","",results[key][:acceptedItemsStats][:qualities][j-1],results[key][:acceptedItemsStats][:popularities][j-1],results[key][:acceptedItemsStats][:scores][j-1]]
          end
        end

        3.times do |i|
          rows << []
        end

        rows << ["Recommender System A/B Testing: Time spent in Recommended Learning Objects"]
        rsKeys.each do |key|
          2.times do |i|
            rows << []
          end
          rows << [key.to_s]
          rows << ["Approach A"]
          rows << ["n","time","","times"]
          rows << ["","M","SD"]
          rows << [results[key][:loTimesA].length,results[key][:loTimeA][:mean],results[key][:loTimeA][:sd]]
          results[key][:loTimesA].length.times do |j|
            rows << ["","","",results[key][:loTimesA][j-1]]
          end
          rows << ["Approach B"]
          rows << ["n","time","","times"]
          rows << ["","M","SD"]
          rows << [results[key][:loTimesB].length,results[key][:loTimeB][:mean],results[key][:loTimeB][:sd]]
          results[key][:loTimesB].length.times do |j|
            rows << ["","","",results[key][:loTimesB][j-1]]
          end
        end

        rows.each do |row|
          sheet.add_row row
        end
      end
      prepareFile(filePath)
      p.serialize(filePath)
    end

    puts("A/B Testing Acceptance Results generated at " + filePath)
    puts("Task finished")
  end


  private

  ####################
  # Metrics
  ####################

  def breeze_rscore(scores,options)
    score = 0
    max_score = 0
    alpha = options[:alpha] || 1.5 #Half-life parameter which controls exponential decline of the value of positions.
    d = options[:d] || 1 #Breeze's don't care threshold.
    scores.each_with_index do |s,j|
      score += ([s-d,0].max)/(2 ** ((j-1)/(alpha-1)))
      max_score += ([5-d,0].max)/(2 ** ((j-1)/(alpha-1)))
    end
    #Normalization
    score/max_score.to_f
  end

end