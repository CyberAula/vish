# encoding: utf-8
require 'json'

class VishLoep
  
  def self.getExcursionMetrics(ex)
    Loep.getLO(ex.id){ |response,code|
      if response.class == Hash and response["id_repository"] == ex.id
        fillExcursionMetrics(ex,response)
        if block_given?
          yield response
        end
      end
    }
  end

  def self.fillExcursionMetrics(excursion,loepData)
    if loepData["Metric Score: LORI Weighted Arithmetic Mean"].is_a? Float
      excursion.activity_object.update_column :reviewers_qscore, loepData["Metric Score: LORI Weighted Arithmetic Mean"]
    end

    if loepData["Metric Score: WBLT-S Weighted Arithmetic Mean"].is_a? Float
      excursion.activity_object.update_column :users_qscore, loepData["Metric Score: WBLT-S Weighted Arithmetic Mean"]
    end

    excursion.calculate_qscore
  end

  def self.registerExcursion(ex)
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

    Loep.createLO(lo){ |response,code|
      #TODO: Create assignments through LOEP
      if block_given?
        yield response, code
      end
    }

  end

  def self.registerExcursions(excursions,options=nil)
    unless !options.nil? and options[:async]==true
      return _registerExcursionsSync(excursions,options)
    else
      _registerExcursionsAsync(excursions,options){
        if block_given?
          yield "Finish"
        end
      }
    end
  end

  def self._registerExcursionsSync(excursions,options=nil)
    excursions.each do |excursion|
      VishLoep.registerExcursion(excursion){ |response,code|
        if !options.nil? and options[:trace]==true
          puts "Excursion with id: " + excursion.id.to_s
          puts response.to_s
        end
      }
      sleep 2
    end
    return "Finish"
  end

  def self._registerExcursionsAsync(excursions,options=nil)
    eChunks = excursions.each_slice(25).to_a
    _rChunks(0,eChunks,options){
        yield "F"
    }
  end

  def self._rChunks(cA,eChunks,options=nil)
    _rChunk(0,eChunks[cA],options){
      unless cA==eChunks.length-1
        _rChunks(cA+1,eChunks,options){ yield "F" }
      else
        yield "F"
      end
    }
  end

  def self._rChunk(cB,exs,options=nil)
    VishLoep.registerExcursion(exs[cB]){ |response,code|
      if !options.nil? and options[:trace]==true
        puts "Excursion with id: " + exs[cB].id.to_s
        puts response.to_s
      end

      unless cB==exs.length-1
        _rChunk(cB+1,exs,options){ yield "F" }
      else
        yield "F"
      end
    }
  end

end