# encoding: utf-8
require 'restclient'
require 'json'

class Loep

  #Get LO
  def self.getLO(lo_id)
    params = getParams

    callAPI("GET","los/" + lo_id.to_s,params){ |response,code|
      if block_given?
        yield response, code
      end
    }
  end

  #Create LO
  def self.createLO(lo)
    params = getParams

    params["lo"] = lo
    if params["lo"]["repository"].nil?
      params["lo"]["repository"] = Vish::Application.config.APP_CONFIG['loep']['repository_name']
    end 

    if !params["lo"]["lanCode"].nil?
      loep_langs = ["en", "es", "de", "fr", "it", "nl", "hu"]
      unless loep_langs.include? params["lo"]["lanCode"]
        params["lo"]["lanCode"] =  "lanot"
      end
    end

    callAPI("POST","los",params){ |response,code|
      if block_given?
        yield response, code
      end
    }
  end


  private

  def self.getParams(params=nil)
    if params.nil?
      params = Hash.new
    end
    params["utf8"] = "✓"
    params["app_name"] = Vish::Application.config.APP_CONFIG['loep']['app_name']
    params["auth_token"] = Vish::Application.config.APP_CONFIG['loep']['auth_token']
    params
  end

  def self.callAPI(method,apiPath,params)
    apiBaseURL = getAPIBaseUrl
    apiMethodURL = apiBaseURL+apiPath

    if method.nil?
      method = "GET"
    end

    begin
      case method.upcase
      when "POST"
        RestClient.post(
          apiMethodURL,
          params.to_json,
          :content_type => :json,
          :accept => :json
        ){ |response|
          if block_given?
            yield JSON(response),response.code
          end
        }
      when "GET"
        RestClient.get(
          apiMethodURL,
          {:params => params}
        ){ |response|
          if block_given?
            yield JSON(response),response.code
          end
        }
      else
        if block_given?
          yield "Error in Loep.callAPI: No method specified.",nil
        end
      end

    rescue => e
      if block_given?
        yield "Error in Loep.callAPI. Exception: " + e.message,nil
      end
    end
  end

  def self.getAPIBaseUrl
    loepConfig = Vish::Application.config.APP_CONFIG['loep']
    return loepConfig['domain']+"/api/"+(loepConfig['api_version'] || "v1")+"/"
  end

end