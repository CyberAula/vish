# encoding: utf-8
require 'json'

class VishLoep
  
  def self.registerExcursionInLOEP(ex)
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
    lo["id_repository"] = ex.id
    
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

    elemTypes = VishEditor.getElementTypes(exJSON)

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

    Loep.uploadLO(lo){ |response,code|
      #TODO: Create assignments through LOEP
      if block_given?
        yield response, code
      end
    }

  end

end