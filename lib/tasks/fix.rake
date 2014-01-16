# encoding: utf-8

namespace :fix do

  #Usage
  #Development:   bundle exec rake fix:pictures
  #In production: bundle exec rake fix:pictures RAILS_ENV=production
  task :pictures => :environment do

    puts "#####################################"
    puts "Fixing pictures"
    puts "#####################################"

    #Get all excursions
    excursions = Excursion.all
    excursions.each do |excursion|
      begin
        jsonChange = false
        eJson = JSON(excursion.json)
        eJson["slides"].each do |slide|
          sElements = slide["elements"]
          if sElements != nil
            sElements.each do |el|
              if el["type"]=="image" and el["body"].class == String
                imgPath = el["body"]
                if isWrongImagePath(imgPath)
                  # puts imgPath
                  #Fix it
                  el["body"] = Site.current.config[:documents_hostname][0..-2] + imgPath
                  # puts "Fix image, new URL:"
                  # puts el["body"]
                  jsonChange = true
                end
              end
            end
          end
        end
      if jsonChange
        puts "Excursion ID"
        puts excursion.id
        excursion.update_column :json, eJson.to_json;
      end
      rescue Exception => e
        puts "Exception with excursion id:"
        puts excursion.id.to_s
        puts "Exception message"
        puts e.message
      end
    end

    puts "#####################################"
    puts "Task Finished"
    puts "#####################################"
  end

  def printSeparator
    puts ""
    puts "--------------------------------------------------------------"
    puts ""
  end

  def isWrongImagePath(imagePath)
    return (!imagePath.nil? and imagePath.include?("/pictures/") and !imagePath.include?("vishub") and !imagePath.include?("http://") and !imagePath.include?("https://"))
  end

end


