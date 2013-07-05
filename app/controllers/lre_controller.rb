require 'rest_client'

class LreController < ApplicationController
	LRE_SEARCH_URL = "http://lresearch.eun.org/"
	LRE_DATA_URL = "http://lredata.eun.org/"

    # Enable CORS for last_slide method (http://www.tsheffler.com/blog/?p=428)
	  before_filter :cors_preflight_check, :only => [ :search_lre]
	  after_filter :cors_set_access_control_headers, :only => [ :search_lre]

	  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

	#this method will do like a proxy to the LRE
	#params received "q" with the query to search, for example ((content[nature]))((lrt[image]))
	#                "limit" with the number of object to search
	def search_lre
		response = RestClient.get LRE_SEARCH_URL, {:params => {:cnf => params[:q], :limit => params[:limit]}}
		if response.code != 200
			error = t("lre.search_error", :code => response.code)
		else
			begin
		      parsed_json = JSON(response.body)
		    rescue
		      logger.fatal "There was an error with the json returned. The json was: " + response.body
		      error = t("lre.json_error")
		    end
			if parsed_json["error"]
				error = parsed_json["error"]
			else
				#let's get the data for those ids returned
				final_json = getJSONForIds(parsed_json["ids"])
				if final_json.class==Hash && final_json["error"]
					error = final_json["error"]
				end
			end
		end		
		
        if error
          render :json => {"error"=> error}
        else
          #answers with the json in LRE format
          render :json => {"results" => final_json}
        end	   
  	end


  	#method to get the data for the ids, this calls to LRE_DATA_URL to ask for the metadata
  	#it will return a json object to return it to the ViSH editor
  	def getJSONForIds(ids)
  		logger.info "We are going to request the LRE for these ids: " + ids
  		ids_alone = ids.delete "{}"
  		if ids_alone == ""
  			return []
  		end
  		response = RestClient.get LRE_DATA_URL, {:params => {:ids => ids_alone, :format => "json"}}  		
  		if response.code != 200
			return {"error"=> t("lre.data_error", :code => response.code)}
		else
	  		begin
		      parsed_json = JSON(response.body)
		    rescue
			  logger.fatal "There was an error with the json returned. The json was: " + response.body		      
		      return {"error"=> t("lre.json_error")}
		    end
		    logger.info "We got " + parsed_json.length.to_s + " objects as a response"
		    
	  		return parsed_json #lre returns an array with the contents
		end	
  	end

end
