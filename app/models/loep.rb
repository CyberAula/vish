# encoding: utf-8
require 'restclient'
require 'json'
require 'base64'

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

    callAPI("POST","los",params){ |response,code|
      if block_given?
        yield response, code
      end
    }
  end

  #Create SessionToken
  def self.createSessionToken()
    callAPI("POST","session_token"){ |response,code|
      if block_given?
        if code===200
          yield response["auth_token"], code
        else
          yield nil, code
        end
      end
    }
  end


  private

  def self.callAPI(method,apiPath,params={})
    apiBaseURL = getAPIBaseUrl
    apiMethodURL = apiBaseURL+apiPath

    if method.nil?
      method = "GET"
    end

    begin
      case method.upcase
      when "POST"
        response = RestClient::Request.execute(
          :method => :post,
          :url => apiMethodURL,
          :payload => params,
          :headers => {:'Authorization' => getBasicAuthHeader, :content_type => :json, :accept => :json}
        ){ |response|
          if block_given?
            yield JSON(response),response.code
          end
        }
      when "GET"
        response = RestClient::Request.execute(
          :method => :get,
          :url => apiMethodURL,
          :headers => {:'Authorization' => getBasicAuthHeader}
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

  def self.getBasicAuthHeader
    auth_header = 'Basic ' + Base64.encode64("#{Vish::Application.config.APP_CONFIG['loep']['app_name']}:#{Vish::Application.config.APP_CONFIG['loep']['auth_token']}").gsub("\n","")
  end

  def self.getParams(params=nil)
    if params.nil?
      params = Hash.new
    end
    params["utf8"] = "✓"
    params
  end

end