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

  task :rs, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["trsystem:prepare"].invoke
    end

    writeInTRS("")
    writeInTRS("Recommender System Report")
    writeInTRS("")

  end

  def writeInTRS(line)
    write(line,TRS_FILE_PATH)
  end

end
