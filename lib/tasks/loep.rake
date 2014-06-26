# encoding: utf-8
require 'restclient'
require 'json'
require 'base64'


namespace :loep do

  #Usage
  #Development:   bundle exec rake loep:bringLOs
  #In production: bundle exec rake loep:bringLOs RAILS_ENV=production
  task :bringLOs => :environment do

    puts "#####################################"
    puts "#####################################"
    puts "Bringing LOs from ViSH to LOEP"
    puts "#####################################"
    puts "#####################################"

    excursions = Excursion.all.select{ |ex| ex.draft==false }
    # excursions = [Excursion.find(690)]
    # excursions = ActivityObject.tagged_with("ViSHCompetition2013").map(&:object).select{|a| a.class==Excursion && a.draft == false}
    
    excursionChunks = excursions.each_slice(25).to_a
    recursiveBringChunk(excursionChunks,excursionChunks.length,0){
      finish
    }
  end

end

def recursiveBringChunk(chunks,nChunks,index)
    cChunk = chunks[index]
    bringChunk(cChunk){
      # After Bring "Chunk"
      index = index + 1
      if index < nChunks
        recursiveBringChunk(chunks,nChunks,index){ yield "Finish" }
      else
        yield "Finish"
      end
    }
end

def bringChunk(excursions)
  recursiveBringLO(excursions,excursions.length,0){
    yield "Finish"
  }
end


def recursiveBringLO(excursions,nExcursions,index)
  cExcursion = excursions[index]
  bringLO(cExcursion){ |response,code|
    # After Bring "LO"
    index = index + 1
    if index < nExcursions
      recursiveBringLO(excursions,nExcursions,index){ yield "Finish" }
    else
      yield response, code
    end
  }
end

def finish
  puts "---------------------------------------------------------"
  puts "#####################################"
  puts "#####################################"
  puts "Finished. All LOs have been brought to the LOEP platform"
  puts "#####################################"
  puts "#####################################"
end

def invokeApiMethod(url,obj)
  begin
    RestClient.post(
      url,
      obj.to_json,
      :content_type => :json,
      :accept => :json
    ){
      |response|
      yield JSON(response),response.code
    }
  rescue => e
    puts "Exception: " + e.message
  end
end

def bringLO(lo)
  if lo.nil?
    puts "Learning Object is nil"
    yield nil
    return
  end

  loJSON = JSON(lo.json)

  if !lo.title.nil?
    name = lo.title
  else
    name = "Untitled"
  end
  puts "---------------------------------------------------------"
  puts "Bringing Learning Object with id: " + lo.id.to_s + " and name: " + name


  params = Hash.new
  params["utf8"] = "✓"
  # Authentication
  # params["authentication"] = 'Basic ' + Base64.encode64("name" + ':' + "password")
  # params["authenticity_token"] = '';
  params["app_name"] = "ViSH"
  params["auth_token"] = Vish::Application.config.loep_token

  #LO
  params["lo"] = Hash.new
  if !lo.title.blank?
    params["lo"]["name"] = lo.title
  end
  params["lo"]["url"] = Vish::Application.config.full_domain + "/excursions/" + lo.id.to_s
  params["lo"]["repository"] = "ViSH"
  if !lo.description.blank?
    params["lo"]["description"] = lo.description
  end
  
  if !loJSON["subject"].nil?
    params["lo"]["categories"] = loJSON["subject"]
  end

  if !lo.tag_list.nil? and lo.tag_list.is_a? Array
    params["lo"]["tag_list"] = lo.tag_list.join(",")
  end

  #Need to be transformed to params["lo"]["language_id"]
  # params["lo"]["lanCode"] =  "en"
  loep_langs = ["en", "es", "de", "fr", "it", "nl", "hu"]
  if !loJSON["language"].nil? and loJSON["language"]!="independent" and loJSON["language"]!="ot" and loep_langs.include? loJSON["language"]
    params["lo"]["lanCode"] =  loJSON["language"]
  elsif loJSON["language"]=="independent"
    #LO independent of Language
    params["lo"]["lanCode"] =  "lanin"
  else
    #Other by default
    params["lo"]["lanCode"] =  "lanot"
  end

  params["lo"]["lotype"] = "VE slideshow"
  params["lo"]["technology"] = "HTML"

  elemTypes = getElementTypesOfExcursion(loJSON)

  params["lo"]["hasText"] = elemTypes.include?("text") ? "1" : "0"
  params["lo"]["hasImages"] = elemTypes.include?("image") ? "1" : "0"
  params["lo"]["hasVideos"] = elemTypes.include?("video") ? "1" : "0"
  params["lo"]["hasAudios"] = elemTypes.include?("audio") ? "1" : "0"
  params["lo"]["hasQuizzes"] = elemTypes.include?("quiz") ? "1" : "0"
  params["lo"]["hasWebs"] = (elemTypes.include?("web") or elemTypes.include?("snapshot")) ? "1" : "0"
  params["lo"]["hasFlashObjects"] = elemTypes.include?("flash") ? "1" : "0"
  params["lo"]["hasApplets"] = elemTypes.include?("applet") ? "1" : "0"
  params["lo"]["hasDocuments"] = elemTypes.include?("document") ? "1" : "0"
  params["lo"]["hasFlashcards"] = elemTypes.include?("flashcard") ? "1" : "0"
  params["lo"]["hasVirtualTours"] = elemTypes.include?("VirtualTour") ? "1" : "0"
  params["lo"]["hasEnrichedVideos"] = elemTypes.include?("enrichedvideo") ? "1" : "0"

  productionURL = 'http://loep.global.dit.upm.es/api/v1/los'
  developmentURL = 'http://localhost:8080/api/v1/los'

  isProduction = (!ENV['RAILS_ENV'].nil?) and (ENV['RAILS_ENV']=="production")
  isDevelopment = !isProduction

  if isProduction
    targetURL = productionURL
  else
    targetURL = developmentURL
  end

  invokeApiMethod(targetURL,params){ |response,code|
    if(code >= 400 and code <=500)
      puts "Error. " + "Response code: " + code.to_s
    else
      puts "Success"
    end
    puts response

    yield response, code
  }
end

def getElementTypesOfExcursion(loJSON)
  types = []
  begin
    slides = loJSON["slides"]
    types = types + slides.map { |s| s["type"] }
    slides.each do |slide|
      els = slide["elements"]
      if !els.nil?
        types = types + els.map {|el| getElType(el)}
      end
    end
    types.uniq!
    types = types.reject { |type| type.nil? }
  rescue => e
    puts "Exception"
    puts e.message
  end
  types
end

def getElType(el)
  if el.nil?
    return nil
  end

  elType = el["type"]

  if elType != "object"
    return elType
  else
    #Look in body param
    elBody = el["body"]

    if elBody.nil? or !elBody.is_a? String
      return elType
    end

    if elBody.include?("http://docs.google.com")
      return "document"
    end

    if elBody.include?("www.youtube.com")
      return "video"
    end

    if elBody.include?(".swf") and elBody.include?("embed")
      return "flash"
    end

    return "web"

  end
end
