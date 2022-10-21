# encoding: utf-8

namespace :fix do

  #Usage
  #Development:   bundle exec rake fix:resetScormTimestamps
  #In production: bundle exec rake fix:resetScormTimestamps RAILS_ENV=production
  task :resetScormTimestamps => :environment do
    printTitle("Reset SCORM timestamps")

    Excursion.all.map { |ex| 
      ex.update_column :scorm2004_timestamp, nil
      ex.update_column :scorm12_timestamp, nil
    }

    printTitle("Task Finished")
  end

  #Usage
  #Development:   bundle exec rake fix:fillExcursionsLanguage
  #In production: bundle exec rake fix:fillExcursionsLanguage RAILS_ENV=production
  task :fillExcursionsLanguage => :environment do

    printTitle("Filling Excursions language")

    validLanguageCodes = ["de","en","es","fr","it","pt","ru"]
    #"ot" is for "other"

    Excursion.all.map { |ex|
      eJson = JSON(ex.json)

      lan = eJson["language"]
      emptyLan = (lan.nil? or !lan.is_a? String or lan=="independent")

      if emptyLan and !Vish::Application.config.APP_CONFIG["languageDetectionAPIKEY"].nil?
        #Try to infer language
        #Use https://github.com/detectlanguage/detect_language gem

        stringToTestLanguage = ""
        if ex.title.is_a? String and !ex.title.blank?
          stringToTestLanguage = stringToTestLanguage + ex.title + " "
        end
        if ex.description.is_a? String and !ex.description.blank?
          stringToTestLanguage = stringToTestLanguage + ex.description + " "
        end

        if stringToTestLanguage.is_a? String and !stringToTestLanguage.blank?
          detectionResult = (DetectLanguage.detect(stringToTestLanguage) rescue [])
          detectionResult.each do |result|
            if result["isReliable"] == true
              detectedLanguageCode = result["language"]
              if validLanguageCodes.include? detectedLanguageCode
                lan = detectedLanguageCode
              else
                lan = "ot"
              end
              emptyLan = false
              break
            end
          end
        end
      end

      if !emptyLan
        ao = ex.activity_object
        if ao.language != lan
          ao.update_column :language, lan
        end

        if eJson["language"] != lan
          eJson["language"] = lan
          ex.update_column :json, eJson.to_json
        end
      end

    }

    printTitle("Task Finished")
  end

  #Usage
  #Development:   bundle exec rake fix:updateScormPackages
  #In production: bundle exec rake fix:updateScormPackages RAILS_ENV=production
  task :updateScormPackages => :environment do
    printTitle("Updating SCORM Packages")
    Scormfile.record_timestamps=false
    ActivityObject.record_timestamps=false

    Scormfile.all.each do |scormfile|
      begin
        scormfile.updateScormfile
      rescue Exception => e
        puts "Exception in Scormfile with id '" + scormfile.id.to_s + "'. Exception message: " + e.message
      end
    end

    Rake::Task["fix:resetScormTimestamps"].invoke

    Scormfile.record_timestamps=true
    ActivityObject.record_timestamps=true
    printTitle("Task finished")
  end

  #Usage
  #Development:   bundle exec rake fix:updateImscPackages
  #In production: bundle exec rake fix:updateImscPackages RAILS_ENV=production
  task :updateImscPackages => :environment do
    printTitle("Updating IMS Content Packages")
    Imscpfile.record_timestamps=false
    ActivityObject.record_timestamps=false

    Imscpfile.all.each do |imscpfile|
      begin
        imscpfile.updateImscpfile
      rescue Exception => e
        puts "Exception in Imscpfile with id '" + imscpfile.id.to_s + "'. Exception message: " + e.message
      end
    end

    Imscpfile.record_timestamps=true
    ActivityObject.record_timestamps=true
    printTitle("Task finished")
  end

  #Usage
  #Development:   bundle exec rake fix:updateWebapps
  #In production: bundle exec rake fix:updateWebapps RAILS_ENV=production
  task :updateWebapps => :environment do
    printTitle("Updating Web Applications")
    Webapp.record_timestamps=false
    ActivityObject.record_timestamps=false

    Webapp.all.each do |webapp|
      begin
        webapp.updateWebapp
      rescue Exception => e
        puts "Exception in Webapp with id '" + webapp.id.to_s + "'. Exception message: " + e.message
      end
    end

    Webapp.record_timestamps=true
    ActivityObject.record_timestamps=true
    printTitle("Task finished")
  end

  #Usage
  #Development:   bundle exec rake fix:codeResourcesExcursions
  #In production: bundle exec rake fix:codeResourcesExcursions RAILS_ENV=production
  task :codeResourcesExcursions => :environment do

    printTitle("Fixing code resources in excursions")

    #Get all excursions
    excursions = Excursion.all
    excursions.each do |excursion|
      begin
        jsonChange = false
        eJson = JSON(excursion.json)
        eJson["slides"].each do |slide|
          sElements = []
          if slide["type"] == "standard"
            sElements << slide["elements"]
          else
            if slide["slides"].is_a? Array
              slide["slides"].each do |subslide|
                sElements << subslide["elements"]
              end
            end
          end
          sElements.each do |elArray|
            elArray.each do |el|
              if el["type"]=="object" and el["body"].class == String and el["body"].include?("vishubcode.global.dit.upm.es") and el["body"].include?("</iframe>")
                newBody = el["body"].gsub("vishubcode.global.dit.upm.es",Vish::Application.config.APP_CONFIG['code_domain'])
                el["body"] = newBody 
                jsonChange = true
              end
            end
          end
        end
        if jsonChange
          puts "Excursion ID"
          puts excursion.id.to_s
          excursion.update_column :json, eJson.to_json
        end
      rescue Exception => e
        puts "Exception with excursion id:"
        puts excursion.id.to_s
        puts "Exception message"
        puts e.message
      end
    end

    printTitle("Task Finished")
  end

  #Usage
  #Development:   bundle exec rake fix:updateCodeResources
  #In production: bundle exec rake fix:updateCodeResources RAILS_ENV=production
  task :updateCodeResources => :environment do
    printTitle("Updating code resources")
    Rake::Task["fix:updateScormPackages"].invoke
    Rake::Task["fix:updateWebapps"].invoke
    Rake::Task["fix:updateImscPackages"].invoke
    Rake::Task["fix:codeResourcesExcursions"].invoke
    printTitle("Task finished")
  end

  #Usage
  #Development:   bundle exec rake fix:createTestContest
  task :createTestContest => :environment do
    printTitle("Create a test Contest")

    c = Contest.find_by_template("test")
    c.destroy unless c.nil?

    ml = MailList.find_by_name("MailList Contest Test")
    ml.destroy unless ml.nil?

    #Create MailList
    ml = MailList.new
    ml.name = "MailList Contest Test"
    ml.settings = ({"require_login" => "false", "require_name" => "false"}).to_json
    ml.save!

    c = Contest.new
    c.name = "test"
    c.template = "test"
    c.show_in_ui = true
    c.settings = ({"enroll" => "true", "submission" => "one_per_user", "submission_require_enroll" => "false"}).to_json
    c.mail_list_id = ml.id
    c.save!

    cc = ContestCategory.new
    cc.name = "General"
    cc.contest_id = c.id
    cc.save!

    printTitle("Task finished. Test contest created with id " + c.id.to_s)
  end

 #Usage
  #Development:   bundle exec rake fix:createTestContest
  task :createTestOtherDataContest => :environment do
    printTitle("Create a test Contest")

    c = Contest.find_by_template("test")
    c.destroy unless c.nil?

    ml = MailList.find_by_name("MailList Contest Test")
    ml.destroy unless ml.nil?

    #Create MailList
    ml = MailList.new
    ml.name = "MailList Contest Test"
    ml.settings = ({"require_login" => "false", "require_name" => "false"}).to_json
    ml.save!

    c = Contest.new
    c.name = "test"
    c.template = "test"
    c.show_in_ui = true
    c.settings = ({"enroll" => "true", "submission" => "one_per_user", "submission_require_enroll" => "false", "additional_fields" => ["province","postal_code"]}).to_json
    c.mail_list_id = ml.id
    c.save!

    cc = ContestCategory.new
    cc.name = "General"
    cc.contest_id = c.id
    cc.save!

    printTitle("Task finished. Test contest created with id " + c.id.to_s)
  end

  #Usage
  #Development:   bundle exec rake fix:removeSpamUsers
  #In production: bundle exec rake fix:removeSpamUsers RAILS_ENV=production
  task :removeSpamUsers => :environment do
    printTitle("Removing spam users")
    users = User.where("CONFIRMED_AT is NULL AND SIGN_IN_COUNT < 2")
    users = users.select{|u| ActivityObject.authored_by(u).count == 0 }
    users = users.select{|u| u.actor_historial.nil? or u.actor_historial.length < 3 }
    users.each do |u|
      u.destroy
    end

    printTitle("Task finished")
  end

  ####################
  #Task Utils
  ####################

  def printTitle(title)
    if !title.nil?
      puts "#####################################"
      puts title
      puts "#####################################"
    end
  end

  def printSeparator
    puts ""
    puts "--------------------------------------------------------------"
    puts ""
  end

end