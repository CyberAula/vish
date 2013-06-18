require 'rest_client'

class LreController < ApplicationController
	LRE_SEARCH_URL = "http://lresearch.eun.org/"
	LRE_DATA_URL = "http://lredata.eun.org/"


	#this method will do like a proxy to the LRE
	#params received "q" with the query to search, for example ((content[nature]))((lrt[image]))
	#                "limit" with the number of object to search
	def search_lre
		puts params[:q]  #full query 
		response = RestClient.get LRE_SEARCH_URL, {:params => {:cnf => params[:q], :limit => params[:limit]}}
		if response.code != 200
			error = t("lre.search_error", :code => response.code)
		else
			parsed_json = JSON(response.body)
			if parsed_json["error"]
				error = parsed_json["error"]
			else
				#let's get the data for those ids returned
				final_json = getIds(parsed_json["ids"])
				if final_json["error"]
					error = final_json["error"]
				end
			end
		end
		
		respond_to do |format|	      
	      format.json {
	        if error
	          render :json => {"error"=> error}
	        else
	          #answers with the json in LRE format
	          render :json => final_json
	        end
	      }
    	end
  	end


  	#method to get the data for the ids, this calls to LRE_DATA_URL to ask for the metadata
  	#it will return a json object to return it to the ViSH editor
  	def getIds(ids)
  		response = RestClient.get LRE_DATA_URL, {:params => {:ids => ids, :format => "json"}}  		
  		if response.code != 200
			error = t("lre.data_error", :code => response.code)
		else
	  		parsed_json = JSON(response.body)
	  		return parsed_json
		end	
  	end

end
