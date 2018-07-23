# encoding: utf-8

namespace :loep do

  #Usage
  #Development:   bundle exec rake loep:sendLOs
  #In production: bundle exec rake loep:sendLOs RAILS_ENV=production
  task :sendLOs => :environment do

    puts "#####################################"
    puts "Sending evaluable resources from ViSH to LOEP"
    puts "#####################################"

    evaluableAndPublicAOs = ActivityObject.where("object_type in (?) and scope=0", VishConfig.getAvailableEvaluableModels).order("created_at DESC")
    
    VishLoep.sendActivityObjects(evaluableAndPublicAOs,{:sync=>true,:trace=>true})
    # Async
    # VishLoep.sendActivityObjects(evaluableAndPublicAOs,{:async=>true,:trace=>true})
  end

  #Usage
  #Development:   bundle exec rake loep:getAllMetrics
  #In production: bundle exec rake loep:getAllMetrics RAILS_ENV=production
  task :getAllMetrics => :environment do
    puts "#####################################"
    puts "Getting quality metrics from LOEP and updating ViSH database"
    puts "#####################################"

    ActivityObject.where("object_type in (?)", VishConfig.getAvailableEvaluableModels).order("created_at DESC").each do |ao|
      VishLoep.getActivityObjectMetrics(ao){ |response|
        puts "Metrics for resource: " + ao.getGlobalId
        puts response
      }
      sleep 2
    end
  end

end