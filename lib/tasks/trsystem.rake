# encoding: utf-8
TRS_FILE_PATH = "reports/trsystem.txt";

namespace :trsystem do

  #Usage
  #Development:   bundle exec rake trsystem:all
  #In production: bundle exec rake trsystem:all RAILS_ENV=production
  task :all => :environment do
    Rake::Task["trsystem:prepare"].invoke
    Rake::Task["trsystem:usage"].invoke(false)
    Rake::Task["trsystem:rs"].invoke(false)
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

    totalSlides = 0
    totalDuration = 0

    vvEntries.each do |e|
      # begin
        d = JSON(e["data"]) rescue {}
        # chronologyEntries = d["chronology"].values
        nSlides = d["chronology"].values.map{|c| c["slideNumber"]}.uniq.length
        # tDuration = chronologyEntries.map{|c| c["duration"].to_f}.sum
        tDuration = d["duration"].to_f

        if nSlides.is_a? Integer and tDuration.is_a? Float
          totalSlides = totalSlides + nSlides
          totalDuration = totalDuration + tDuration
        end
      # rescue
      # end
    end

    writeInTRS("Average time per slide:")
    if totalDuration > 0
      writeInTRS((totalDuration/totalSlides.to_f).round(2).to_s + " (s)")
    else
      writeInTRS("0 (s)")
    end

  end

  #Usage
  #Development:   bundle exec rake trsystem:rs
  #In production: bundle exec rake trsystem:rs RAILS_ENV=production
  task :rs, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Recommender System Report")
    writeInTRS("")

    vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer")

    recTSD = {}

    recTSD["Random"] = {}
    recTSD["Random"]["totalRec"] = 0
    recTSD["Random"]["totalRecShow"] = 0
    recTSD["Random"]["totalRecAccepted"] = 0
    recTSD["Random"]["totalRecDenied"] = 0

    recTSD["ViSHRecommenderSystem"] = {}
    recTSD["ViSHRecommenderSystem"]["totalRec"] = 0
    recTSD["ViSHRecommenderSystem"]["totalRecShow"] = 0
    recTSD["ViSHRecommenderSystem"]["totalRecAccepted"] = 0
    recTSD["ViSHRecommenderSystem"]["totalRecDenied"] = 0

    vvEntries.each do |e|
      recData = JSON(e["data"])["rs"] rescue nil
      unless recData.nil? or recData["tdata"].nil?
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
          end
        end
      end
    end

    writeInTRS("")
    writeInTRS("Recommender System: Random")
    writeInTRS("Showed Recommendations:")
    writeInTRS(recTSD["Random"]["totalRecShow"])
    writeInTRS("Accepted Recommendations:")
    writeInTRS(recTSD["Random"]["totalRecAccepted"])
    writeInTRS("Denied Recommendations:")
    writeInTRS(recTSD["Random"]["totalRecDenied"])

    writeInTRS("")
    writeInTRS("Recommender System: ViSH Recommender")
    writeInTRS("Showed Recommendations:")
    writeInTRS(recTSD["ViSHRecommenderSystem"]["totalRecShow"])
    writeInTRS("Accepted Recommendations:")
    writeInTRS(recTSD["ViSHRecommenderSystem"]["totalRecAccepted"])
    writeInTRS("Denied Recommendations:")
    writeInTRS(recTSD["ViSHRecommenderSystem"]["totalRecDenied"])
  end

  def writeInTRS(line)
    write(line,TRS_FILE_PATH)
  end

end
