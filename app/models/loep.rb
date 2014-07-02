# encoding: utf-8
require 'restclient'
require 'json'

class LOEP

  def self.uploadLO(lo)
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

    invokePostApiMethod("los",params){ |response,code|
      yield response, code
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

  def self.invokePostApiMethod(method,params)
    apiURL = getAPIUrl
    apiMethodURL = apiURL+method

    begin
      RestClient.post(
        apiMethodURL,
        params.to_json,
        :content_type => :json,
        :accept => :json
      ){ |response|
        yield JSON(response),response.code
      }
    rescue => e
      puts "Exception: " + e.message
    end
  end

  def self.getAPIUrl
    loepConfig = Vish::Application.config.APP_CONFIG['loep']
    return loepConfig['domain']+"/api/"+(loepConfig['api_version'] || "v1")+"/"
  end

end