# encoding: utf-8
RS_FILE_PATH = "reports/rs.txt"

namespace :rs do

  task :prepare do
    require "#{Rails.root}/lib/task_utils"
    prepareFile(RS_FILE_PATH)
    write("Recommender System Stats",RS_FILE_PATH)
  end

  #Usage
  #Development:   bundle exec rake rs:performanceStats
  #In production: bundle exec rake rs:performanceStats RAILS_ENV=production
  task :performanceStats, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["rs:prepare"].invoke
    end

    write("Recommender System: Calcuting performance stats",RS_FILE_PATH)

    ns = [1,5,10,20,50,100,250,500,1000,2000,10000,100000]
    iterations = 100

    users = User.all.reject{|u| u.nil?}.sample(iterations)
    excursions = Excursion.all.reject{|e| e.nil? or e.draft==true}.sample(iterations)


    #Item-based recommendation
    write("Use case: Recommend excursions to a user taking into account other excursions",RS_FILE_PATH)

    iterationTimesItem = []
    lastIterationTimesItem = []

    ns.each do |n|
      lastIterationTimesItem = []
      iterationTimesItem.push("NewIteration")

      iterations.times do |i|
        iUser = users[i]
        iExcursion = excursions[i]
        options = {:n => n, :nMax => n, :models => [Excursion], :model_names => ["Excursion"], :test => true}
        iTimeStart = Time.now
        RecommenderSystem.resource_suggestions(iUser,iExcursion,options)
        iElapsedTime = (Time.now - iTimeStart).round(1)
        iterationTimesItem.push(iElapsedTime)
        lastIterationTimesItem.push(iElapsedTime)
      end

      nElapsedTime = (lastIterationTimesItem.sum)/iterations.round(1)

      write("n: " + n.to_s,RS_FILE_PATH)
      write("Elapsed time: " + nElapsedTime.to_s + " (s)",RS_FILE_PATH)
    end

    write("Iteration times",RS_FILE_PATH)
    write(iterationTimesItem.to_s,RS_FILE_PATH)


    #User-based recommendation
    write("",RS_FILE_PATH)
    write("Use case: Recommend excursions to a user",RS_FILE_PATH)

    iterationTimesUser = []
    lastIterationTimesUser = []

    ns.each do |n|
      lastIterationTimesUser = []
      iterationTimesUser.push("NewIteration")

      iterations.times do |i|
        iUser = users[i]
        options = {:n => n, :nMax => n, :models => [Excursion], :model_names => ["Excursion"], :test => true}
        iTimeStart = Time.now
        RecommenderSystem.resource_suggestions(iUser,nil,options)
        iElapsedTime = (Time.now - iTimeStart).round(1)
        iterationTimesUser.push(iElapsedTime)
        lastIterationTimesUser.push(iElapsedTime)
      end

      nElapsedTime = (lastIterationTimesUser.sum)/iterations.round(1)

      write("n: " + n.to_s,RS_FILE_PATH)
      write("Elapsed time: " + nElapsedTime.to_s + " (s)",RS_FILE_PATH)
    end

    write("Iteration times",RS_FILE_PATH)
    write(iterationTimesUser.to_s,RS_FILE_PATH)


    #Recommend items for anonymous users
    write("",RS_FILE_PATH)
    write("Use case: Recommend excursions to anonymous users taking into account other excursions",RS_FILE_PATH)

    iterationTimesItemAnonymous = []
    lastIterationTimesItemAnonymous = []

    ns.each do |n|
      lastIterationTimesItemAnonymous = []
      iterationTimesItemAnonymous.push("NewIteration")

      iterations.times do |i|
        iUser = users[i]
        iExcursion = excursions[i]
        options = {:n => n, :nMax => n, :models => [Excursion], :model_names => ["Excursion"], :test => true}
        iTimeStart = Time.now
        RecommenderSystem.resource_suggestions(iUser,iExcursion,options)
        iElapsedTime = (Time.now - iTimeStart).round(1)
        iterationTimesItemAnonymous.push(iElapsedTime)
        lastIterationTimesItemAnonymous.push(iElapsedTime)
      end

      nElapsedTime = (lastIterationTimesItemAnonymous.sum)/iterations.round(1)

      write("n: " + n.to_s,RS_FILE_PATH)
      write("Elapsed time: " + nElapsedTime.to_s + " (s)",RS_FILE_PATH)
    end

    write("Iteration times",RS_FILE_PATH)
    write(iterationTimesItemAnonymous.to_s,RS_FILE_PATH)
  end

  #Usage
  #Development:   bundle exec rake rs:performanceTest
  #In production: bundle exec rake rs:performanceTest RAILS_ENV=production
  task :performanceTest, [:prepare] => :environment do |t,args|
    #Global params here.
    nIterations = 100

    iTimeStart = Time.now
    nIterations.times do |i|
      #Case 1 code
    end
    nElapsedTime = (Time.now - iTimeStart)/nIterations.round(1)
    puts("(Case 1) Elapsed time: " + nElapsedTime.to_s + " (s)")

    iTimeStart = Time.now
    nIterations.times do |i|
      #Case 2 code
    end
    nElapsedTime = (Time.now - iTimeStart)/nIterations.round(1)
    puts("(Case 2) Elapsed time: " + nElapsedTime.to_s + " (s)")

    #More cases...

  end

end
