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

    iterationTimes = []
    users = User.all.reject{|u| u.nil?}
    excursions = Excursion.all.reject{|e| e.nil? or e.draft==true}
    
    ns.each do |n|
      nTimeStart = Time.now

      iterations.times do |i|
        iUser = users.sample
        iExcursion = excursions.sample
        iTimeStart = Time.now
        RecommenderSystem.excursion_suggestions(iUser,iExcursion,{:n => n, :random => false})
        iElapsedTime = (Time.now - iTimeStart).round(1)
        iterationTimes.push(iElapsedTime)
      end

      nElapsedTime = (Time.now - nTimeStart)/iterations.round(1)

      write("n: " + n.to_s,RS_FILE_PATH)
      write("Elapsed time: " + nElapsedTime.to_s + " (s)",RS_FILE_PATH)
    end

    write("Iteration times",RS_FILE_PATH)
    write(iterationTimes.to_s,RS_FILE_PATH)
  end

end
