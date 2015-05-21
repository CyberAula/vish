# encoding: utf-8
require 'json'

class VishLoep
 
  def self.getActivityObjectMetrics(ao)
    Loep.getLO(ao.getGlobalId){ |response,code|
      if response.class == Hash and response["id_repository"] == ao.getGlobalId
        fillActivityObjectMetrics(ao,response)
        if block_given?
          yield response
        end
      end
    }
  end

  def self.fillActivityObjectMetrics(ao,loepData)
    if loepData["Metric Score: LORI WAM CW"].is_a? Float
      ao.update_column :reviewers_qscore, loepData["Metric Score: LORI WAM CW"]
    end

    if loepData["Metric Score: WBLT-S Arithmetic Mean"].is_a? Float
      ao.update_column :users_qscore, loepData["Metric Score: WBLT-S Arithmetic Mean"]
    end

    if loepData["Metric Score: WBLT-T Arithmetic Mean"].is_a? Float
      ao.update_column :teachers_qscore, loepData["Metric Score: WBLT-T Arithmetic Mean"]
    end

    ao.calculate_qscore
  end

  def self.registerActivityObject(ao)
    if ao.nil? or ao.object.nil?
      if block_given?
        yield "Activity Object is nil", nil
      end
      return "Activity Object is nil"
    end

    #Compose the object to be sent to LOEP
    lo = Hash.new

    unless ao.title.blank?
      lo["name"] = ao.title
    end

    lo["url"] = ao.getUrl
    lo["repository"] = Vish::Application.config.APP_CONFIG['loep']['repository_name']
    lo["id_repository"] = ao.getGlobalId
    
    unless ao.description.blank?
      lo["description"] = ao.description
    end

    if !ao.tag_list.nil? and ao.tag_list.is_a? Array and !ao.tag_list.blank?
      lo["tag_list"] = ao.tag_list.join(",")
    end

    unless ao.language.blank?
      case ao.language
      when "independent"
        lo["lanCode"] =  "lanin"
      else
        lo["lanCode"] =  ao.language
      end
    end

    case ao.object_type
    when "Excursion"
      lo["lotype"] = "veslideshow"
      lo["technology"] = "html"

      exJSON = JSON(ao.object.json)
      elemTypes = VishEditorUtils.getElementTypes(exJSON)
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
    when "Document"
      lo["technology"] = "file"
      case ao.object.class.name
      when "Picture"
        lo["lotype"] = "image"
        lo["hasImages"] = "1"
      when "Video"
        lo["lotype"] = "video"
        lo["hasVideos"] = "1"
      when "Audio"
        lo["lotype"] = "audio"
        lo["hasAudios"] = "1"
      when "Swf"
        lo["lotype"] = "oilo"
        lo["technology"] = "flash"
        lo["hasFlashObjects"] = "1"
      when "Zipfile"
        lo["lotype"] = "oslo"
      when "Officedoc"
        lo["lotype"] = "document"
        lo["hasDocuments"] = "1"
      else
        #"Document"
        lo["lotype"] = "document"
      end
    when "Link","Embed","Scormfile", "Webapp"
      lo["lotype"] = "web"
      lo["technology"] = "html"
      lo["hasWebs"] = "1"
    end

    Loep.createLO(lo){ |response,code|
      #TODO: Create assignments through LOEP
      if block_given?
        yield response, code
      end
    }

  end

  def self.registerActivityObjects(aos,options=nil)
    unless !options.nil? and options[:async]==true
      return _registerActivityObjectsSync(aos,options)
    else
      _registerActivityObjectsAsync(aos,options){
        if block_given?
          yield "Finish"
        end
      }
    end
  end

  def self._registerActivityObjectsSync(aos,options=nil)
    aos.each do |ao|
      VishLoep.registerActivityObject(ao){ |response,code|
        if !options.nil? and options[:trace]==true
          puts "Activity Object with id: " + ao.getGlobalId
          puts response.to_s
        end
      }
      sleep 2
    end
    return "Finish"
  end

  def self._registerActivityObjectsAsync(aos,options=nil)
    eChunks = aos.each_slice(25).to_a
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

  def self._rChunk(cB,aos,options=nil)
    VishLoep.registerActivityObjects(aos[cB]){ |response,code|
      if !options.nil? and options[:trace]==true
        puts "Activity Object with id: " + aos[cB].getGlobalId
        puts response.to_s
      end

      unless cB==aos.length-1
        _rChunk(cB+1,aos,options){ yield "F" }
      else
        yield "F"
      end
    }
  end

end