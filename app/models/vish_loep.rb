# encoding: utf-8
require 'json'

class ViSHLOEP
  
  def self.uploadExcursionToLOEP(ex)
    if ex.nil?
      if block_given?
        yield "Excursion is nil", nil
      end
      return "Excursion is nil"
    end

    exJSON = JSON(ex.json)

    #Compose the object to be sent to LOEP
    lo = Hash.new

    if !ex.title.blank?
      lo["name"] = ex.title
    end
    
    lo["url"] = Vish::Application.config.full_domain + "/excursions/" + ex.id.to_s
    
    if !ex.description.blank?
      lo["description"] = ex.description
    end
    
    if !exJSON["subject"].nil?
      lo["categories"] = exJSON["subject"]
    end

    if !ex.tag_list.nil? and ex.tag_list.is_a? Array
      lo["tag_list"] = ex.tag_list.join(",")
    end

    if !exJSON["language"].nil?
      lo["lanCode"] =  exJSON["language"]
    end

    lo["lotype"] = "VE slideshow"
    lo["technology"] = "HTML"

    elemTypes = getElementTypesOfExcursion(exJSON)

    lo["hasText"] = elemTypes.include?("text") ? "1" : "0"
    lo["hasImages"] = elemTypes.include?("image") ? "1" : "0"
    lo["hasVideos"] = elemTypes.include?("video") ? "1" : "0"
    lo["hasAudios"] = elemTypes.include?("audio") ? "1" : "0"
    lo["hasQuizzes"] = elemTypes.include?("quiz") ? "1" : "0"
    lo["hasWebs"] = (elemTypes.include?("web") or elemTypes.include?("snapshot")) ? "1" : "0"
    lo["hasFlashObjects"] = elemTypes.include?("flash") ? "1" : "0"
    lo["hasApplets"] = elemTypes.include?("applet") ? "1" : "0"
    lo["hasDocuments"] = elemTypes.include?("document") ? "1" : "0"
    lo["hasFlashcards"] = elemTypes.include?("flashcard") ? "1" : "0"
    lo["hasVirtualTours"] = elemTypes.include?("VirtualTour") ? "1" : "0"
    lo["hasEnrichedVideos"] = elemTypes.include?("enrichedvideo") ? "1" : "0"

    LOEP.uploadLO(lo){ |response,code|
      #TODO: Create assignments through LOEP
      if block_given?
        yield response, code
      end
    }

  end

  def self.getElementTypesOfExcursion(loJSON)
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

  def self.getElType(el)
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

end