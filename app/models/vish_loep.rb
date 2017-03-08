# encoding: utf-8
require 'json'

class VishLoep
 
  def self.getActivityObjectMetrics(ao)
    Loep.getLO(getLoepHashForActivityObject(ao,true)){ |response,code|
      if response.class == Hash and response["id_repository"] == ao.getGlobalId
        fillActivityObjectMetrics(ao,response)
        yield response if block_given?
      end
    }
  end

  def self.getActivityObjectsMetrics(aos,options={})
    return _getActivityObjectsMetricsSync(aos,options) unless options[:async]==true
    _getActivityObjectsMetricsAsync(aos,options){
      yield "Finish" if block_given?
    }
  end

  def self.sendActivityObject(ao)
    if ao.nil? or ao.object.nil?
      yield "Activity Object is nil", nil if block_given?
      return "Activity Object is nil"
    end

    #Compose the object to be sent to LOEP
    lo = VishLoep.getLoepHashForActivityObject(ao)
    
    Loep.createOrUpdateLO(lo){ |response,code|
      # Get quality metrics from automatic evaluation methods. 
      # Not necessary because Loep::LosController:update will be called after publishing by LOEP.
      # VishLoep.fillActivityObjectMetrics(ao,response)
      yield response, code if block_given?
    }
  end

  def self.sendActivityObjects(aos,options={})
    return _sendActivityObjectsSync(aos,options) unless options[:async]==true
    _sendActivityObjectsAsync(aos,options){
      yield "Finish" if block_given?
    }
  end

  def self.fillActivityObjectMetrics(ao,loepData)
    ao.update_column :reviewers_qscore, loepData["Metric Score: LORI WAM CW"] if loepData["Metric Score: LORI WAM CW"].is_a? Numeric
    ao.update_column :users_qscore, loepData["Metric Score: WBLT-S Arithmetic Mean"] if loepData["Metric Score: WBLT-S Arithmetic Mean"].is_a? Numeric
    ao.update_column :teachers_qscore, loepData["Metric Score: WBLT-T Arithmetic Mean"] if loepData["Metric Score: WBLT-T Arithmetic Mean"].is_a? Numeric
    ao.update_column :metadata_qscore, loepData["Metric Score: LOM Metadata Quality"] if loepData["Metric Score: LOM Metadata Quality"].is_a? Numeric
    ao.update_column :interaction_qscore, loepData["Metric Score: Interaction Quality"] if loepData["Metric Score: Interaction Quality"].is_a? Numeric
    ao.calculate_qscore
  end


  ############
  ## Utils
  ############

  def self.getLoepHashForActivityObject(ao,min=false)
    return {} if ao.blank?

    lo = Hash.new
    lo["repository"] = Vish::Application.config.APP_CONFIG['loep']['repository_name'] unless Vish::Application.config.APP_CONFIG['loep']['repository_name'].blank?
    lo["id_repository"] = ao.getGlobalId
    return lo if min
    lo["name"] = ao.title unless ao.title.blank?
    lo["description"] = ao.description unless ao.description.blank?
    lo["url"] = ao.getUrl
    lo["tag_list"] = ao.tag_list.join(",") if !ao.tag_list.nil? and ao.tag_list.is_a? Array and !ao.tag_list.blank?

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
      lo["metadata_url"] = ao.getMetadataUrl
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
    when "Link","Embed","Scormfile","Imscpfile","Webapp"
      lo["lotype"] = "web"
      lo["technology"] = "html"
      lo["hasWebs"] = "1"
    end

    #Interactions
    lo["interactions"] = ao.lo_interaction.extended_attributes unless ao.lo_interaction.nil?

    lo
  end

  def self._getActivityObjectsMetricsSync(aos,options={})
    aos.each do |ao|
      VishLoep.getActivityObjectMetrics(ao){ |response,code|
        if options[:trace]==true
          puts "Activity Object with id: " + ao.getGlobalId
          puts response.to_s
        end
      }
      sleep 2
    end
    return "Finish"
  end

  def self._getActivityObjectsMetricsAsync(aos,options={})
    eChunks = aos.each_slice(25).to_a
    _rChunksGetAOs(0,eChunks,options){
        yield "F"
    }
  end

  def self._rChunksGetAOs(cA,eChunks,options={})
    _rChunkGetAOs(0,eChunks[cA],options){
      unless cA==eChunks.length-1
        _rChunksGetAOs(cA+1,eChunks,options){ yield "F" }
      else
        yield "F"
      end
    }
  end

  def self._rChunkGetAOs(cB,aos,options={})
    VishLoep.getActivityObjectMetrics(aos[cB]){ |response,code|
      if options[:trace]==true
        puts "Activity Object with id: " + aos[cB].getGlobalId
        puts response.to_s
      end

      unless cB==aos.length-1
        _rChunkGetAOs(cB+1,aos,options){ yield "F" }
      else
        yield "F"
      end
    }
  end

  def self._sendActivityObjectsSync(aos,options={})
    aos.each do |ao|
      VishLoep.sendActivityObject(ao){ |response,code|
        if options[:trace]==true
          puts "Activity Object with id: " + ao.getGlobalId
          puts response.to_s
        end
      }
      sleep 2
    end
    return "Finish"
  end

  def self._sendActivityObjectsAsync(aos,options={})
    eChunks = aos.each_slice(25).to_a
    _rChunksSendAOs(0,eChunks,options){
        yield "F"
    }
  end

  def self._rChunksSendAOs(cA,eChunks,options={})
    _rChunkSendAOs(0,eChunks[cA],options){
      unless cA==eChunks.length-1
        _rChunksSendAOs(cA+1,eChunks,options){ yield "F" }
      else
        yield "F"
      end
    }
  end

  def self._rChunkSendAOs(cB,aos,options={})
    VishLoep.sendActivityObject(aos[cB]){ |response,code|
      if options[:trace]==true
        puts "Activity Object with id: " + aos[cB].getGlobalId
        puts response.to_s
      end

      unless cB==aos.length-1
        _rChunkSendAOs(cB+1,aos,options){ yield "F" }
      else
        yield "F"
      end
    }
  end

end