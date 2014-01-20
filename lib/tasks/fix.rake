# encoding: utf-8

namespace :fix do

  #Usage
  #Development:   bundle exec rake fix:pictures
  #In production: bundle exec rake fix:pictures RAILS_ENV=production
  task :pictures => :environment do

    printTitle("Fixing pictures")

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
                if _isWrongImagePath(imgPath)
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

    printTitle("Task Finished")
  end

  def _isWrongImagePath(imagePath)
    return (!imagePath.nil? and imagePath.include?("/pictures/") and !imagePath.include?("vishub") and !imagePath.include?("http://") and !imagePath.include?("https://"))
  end


  #Usage
  #Development:   bundle exec rake fix:resetScormTimestamp
  #In production: bundle exec rake fix:resetScormTimestamp RAILS_ENV=production
  task :resetScormTimestamp => :environment do

    printTitle("Reset scorm timestamp")

    Excursion.all.map { |ex| 
      ex.scorm_timestamp = nil; 
      ex.update_column :scorm_timestamp, nil
    }

    printTitle("Task Finished")
  end

  #Usage
  #Development:   bundle exec rake fix:authors
  #In production: bundle exec rake fix:authors RAILS_ENV=production
  task :authors => :environment do

    printTitle("Fix authors and contributors")

    Excursion.all.map { |ex|
      eJson = JSON(ex.json)

      #Fix author
      eJson["author"] = {name: ex.author.name, vishMetadata:{ id: ex.author.id}}

      #Fix contributors
      if ex.contributors
        ex.contributors.uniq!
        ex.contributors.delete(ex.author)
        Excursion.record_timestamps=false
        ex.save!
        Excursion.record_timestamps=true
      end

      if ex.contributors and ex.contributors.length > 0
        eJson["contributors"] = [];
      end

      ex.contributors.each do |contributor|
        eJson["contributors"].push({name: contributor.name, vishMetadata:{ id: contributor.id}});
      end

      ex.update_column :json, eJson.to_json;
    }

    printTitle("Task Finished")
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


####################
## Some manual fixes
####################

# * Set PDFEX permanent = true
# Pdfex.all.map { |pdfex| pdfex.update_column :permanent, true }
# * PDFEx Update pdf page count
# Pdfex.all.map { |pdfex| pdfex.updatePageCount }

# * Actualizar IDs de excursiones en el JSON, poner su id de verdad en vez del activity object, y meterlo en vish metadata
# Excursion.all.map { |ex| ejson = JSON(ex.json); ejson["vishMetadata"]={}; ejson["vishMetadata"]["id"] = ex.id.to_s; ejson.delete("id"); ex.update_column :json, ejson.to_json}

# * Poner scorm_timestamp a nil en todas las ex
# Excursion.all.map { |ex| ex.scorm_timestamp = nil; ex.update_column :scorm_timestamp, nil}


# Avatares defectuosos:

# Caso A: Thumbnails: "/assets/logos/original/excursion-XX.png"

# excursions = Excursion.all.select { |ex| 
# !ex.thumbnail_url.nil? and ex.thumbnail_url.include?("/assets/logos/original/excursion-") and !ex.thumbnail_url.include?("vishub") and !ex.thumbnail_url.include?("http://") and !ex.thumbnail_url.include?("https://")
# }

# Excursion.all.map { |ex| 
# if (!ex.thumbnail_url.nil? and ex.thumbnail_url.include?("/assets/logos/original/excursion-") and !ex.thumbnail_url.include?("vishub") and !ex.thumbnail_url.include?("http://") and !ex.thumbnail_url.include?("https://"))
#   newThumbnailUrl = Site.current.config[:documents_hostname][0..-2] + ex.thumbnail_url;
# ex.update_column :thumbnail_url, newThumbnailUrl;
# ejson = JSON(ex.json); 
# ejson["avatar"]=newThumbnailUrl;
# ex.update_column :json, ejson.to_json;
# end
# }

# Caso B: ViSH Pictures: "/pictures/308.jpg"

# excursions = Excursion.all.select { |ex| 
# !ex.thumbnail_url.nil? and ex.thumbnail_url.include?("/pictures/") and !ex.thumbnail_url.include?("vishub") and !ex.thumbnail_url.include?("http://") and !ex.thumbnail_url.include?("https://")
# }

# Excursion.all.map { |ex| 
# if (!ex.thumbnail_url.nil? and ex.thumbnail_url.include?("/pictures/") and !ex.thumbnail_url.include?("vishub") and !ex.thumbnail_url.include?("http://") and !ex.thumbnail_url.include?("https://"))
#   newThumbnailUrl = Site.current.config[:documents_hostname][0..-2] + ex.thumbnail_url;
# ex.update_column :thumbnail_url, newThumbnailUrl;
# ejson = JSON(ex.json); 
# ejson["avatar"]=newThumbnailUrl;
# ex.update_column :json, ejson.to_json;
# end
# }

# # Configurar correctamente el current Site para desarrollo
# Site.current.config[:documents_hostname] = "http://localhost:3000/"
# Site.current.save!
