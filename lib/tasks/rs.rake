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

    RSEvaluation.where(:status => "Finished").each do |e|
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
  task :accuracy, [:prepare] => :environment do |t,args|
    Rake::Task["rs:prepare"].invoke

    printTitle("Calculating Accuracy using leave-one-out")

    #Get users with more than N liked or authored resources
    N = 4
    authoredResources = ActivityObject.where("activity_objects.object_type IN (?) and activity_objects.scope=0","Excursion").group("activity_objects.id").group_by(&:author_id)
    authoredResources.map{|k,v| authoredResources[k] = v.map{|a| a.object}}
    likedResources = Activity.joins(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id}).where("activity_objects.object_type IN (?) and activity_objects.scope=0","Excursion").group("activities.id").group_by(&:author_id)
    likedResources.map{|k,v| likedResources[k] = v.map{|a| a.direct_object}}

    likedAndAuthoredResources = {}
    (likedResources.keys + authoredResources.keys).uniq.each do |k|
      likedAndAuthoredResources[k] = []
      likedAndAuthoredResources[k] = authoredResources[k] if authoredResources[k].is_a? Array
      lARL = likedAndAuthoredResources[k].length
      if lARL < N and likedResources[k].is_a? Array
        likedAndAuthoredResources[k] = (likedAndAuthoredResources[k] + likedResources[k]).uniq
        lARL = likedAndAuthoredResources[k].length
      end
      likedAndAuthoredResources.delete(k) if lARL < N
    end

    vishActorIds = Actor.find_all_by_email(["virtual.science.hub@gmail.com","virtual.science.hub+1@gmail.com"]).map{|a| a.id}
    likedAndAuthoredResources = likedAndAuthoredResources.select{|k,v| v.length > N}.reject{|k,v| vishActorIds.include? k }
    users = Actor.find(likedAndAuthoredResources.keys)


    #Recommender System settings
    rsSettings = {:preselection_filter_query => false, :preselection_filter_resource_type => false, :preselection_filter_languages => true, :preselection_filter_own_resources => false, :preselection_authored_resources => true, :preselection_size => 200, :preselection_size_min => 100, :only_context => false, :rs_weights => {:los_score=>0.6, :us_score=>0.2, :quality_score=>0.1, :popularity_score=>0.1}, :los_weights => {:title=>0.2, :description=>0.1, :language=>0.5, :keywords=>0.2}, :us_weights => {:language=>0.2, :keywords => 0.2, :los=>0.6}, :rs_filters => {:los_score=>0, :us_score=>0, :quality_score=>0.3, :popularity_score=>0}, :los_filters => {:title => 0, :description => 0, :keywords => 0, :language=>0}, :us_filters => {:language=>0, :keywords => 0, :los=>0}}

    #N values
    ns = [1,5,10,20,500]
    results = {}

    ns.each do |n|
      results[n.to_s] = {:attempts => 0, :successes => 0, :accuracy => 0}
      users.each do |user|
        los = likedAndAuthoredResources[Actor.normalize_id(user)]
        maxUserLos = 2
        los.each do |lo|
          userLos = los.reject{|pastLo| pastLo.id==lo.id}
          2.times do
            #Leave lo out and see if it appears on the n recommendations
            attemptUserLos = userLos.sample(maxUserLos)
            recommendations = RecommenderSystem.resource_suggestions({:n => n, :settings => rsSettings, :user => user, :user_settings => {}, :user_los => attemptUserLos, :max_user_los => maxUserLos})
            success = recommendations.select{|recLo| recLo.id==lo.id}.length > 0 # Success when the out entity is found on recommendations
            results[n.to_s][:attempts] += 1
            results[n.to_s][:successes] += 1 if success
          end
        end
      end
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
  task :performance, [:prepare] => :environment do |t,args|
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

    maxPreselectionSize = Vish::Application::config.max_preselection_size
    Vish::Application::config.max_preselection_size = ns.max

    users = []
    los = []

    publicResources = ActivityObject.getAllPublicResources
    minIterationsPerN.times do |i|
      users << User.limit(1).order(Vish::Application::config.agnostic_random).first.actor
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

    Vish::Application::config.max_preselection_size = maxPreselectionSize

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