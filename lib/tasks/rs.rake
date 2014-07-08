# encoding: utf-8

namespace :rs do

  #Usage
  #Development:   bundle exec rake rs:performanceStats
  #In production: bundle exec rake rs:performanceStats RAILS_ENV=production
  task :performanceStats => :environment do
    puts "Recommender System: Calcuting performance stats"

    ns = [1,5,10,20,50,100,250,500,1000,2000,10000,100000]
    iterations = 100


    iterationTimes = []
    users = User.all.reject{|u| u.nil?}
    excursions = Excursion.all.reject{|e| e.nil? or e.draft==true}
    
    ns.each do |n|
      nTimeStart = Time.now

      iterations.times do |i|
        iTimeStart = Time.now
        RecommenderSystem.excursion_suggestions(users.sample,excursions.sample,{:n => n, :random => false})
        iElapsedTime = (Time.now - iTimeStart).round(1)
        iterationTimes.push(iElapsedTime)
      end

      nElapsedTime = (Time.now - nTimeStart)/iterations.round(1)

      puts "n: " + n.to_s
      puts "Elapsed time: " + nElapsedTime.to_s + " (s)"
    end

    puts "Iteration times"
    puts iterationTimes.to_s

  end

end
