# encoding: utf-8
require 'restclient'
require 'json'
require 'base64'

class Loep

  #Get LO
  def self.getLO(lo)
    params = getParams
    params["repository"] = lo["repository"] unless lo["repository"].blank?
    callAPI("GET","los/" + lo["id_repository"].to_s,params){ |response,code|
      yield response, code if block_given?
    }
  end

  #Create LO
  def self.createOrUpdateLO(lo)
    params = getParams
    params["lo"] = lo

    callAPI("POST","los",params){ |response,code|
      if block_given?
        yield response, code
      end
    }
  end

  #Create SessionToken
  def self.createSessionToken(sessionTokenParams)
    params = {}
    params["session_token"] = sessionTokenParams unless sessionTokenParams.blank?
    callAPI("POST","session_token",params){ |response,code|
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
    method = "GET" if method.nil?

    begin
      case method.upcase
      when "POST"
        response = RestClient::Request.execute(
          :method => :post,
          :url => apiMethodURL,
          :timeout => 8, 
          :open_timeout => 8,
          :payload => params,
          :headers => {:'Authorization' => getBasicAuthHeader, :content_type => :json, :accept => :json}
        ){ |response|
          yield JSON(response),response.code if block_given?
        }
      when "GET"
        response = RestClient::Request.execute(
          :method => :get,
          :url => apiMethodURL,
          :timeout => 8, 
          :open_timeout => 8,
          :payload => params,
          :headers => {:'Authorization' => getBasicAuthHeader}
        ){ |response|
          yield JSON(response),response.code if block_given?
        }
      else
        yield "Error in Loep.callAPI: No method specified.",nil if block_given?
      end
    rescue => e
        yield "Error in Loep.callAPI. Exception: " + e.message,nil if block_given?
    end
  end

  def self.getAPIBaseUrl
    loepConfig = Vish::Application.config.APP_CONFIG['loep']
    loepConfig['domain']+"/api/"+(loepConfig['api_version'] || "v1")+"/"
  end

  def self.getBasicAuthHeader
    auth_header = 'Basic ' + Base64.encode64("#{Vish::Application.config.APP_CONFIG['loep']['app_name']}:#{Vish::Application.config.APP_CONFIG['loep']['auth_token']}").gsub("\n","")
  end

  def self.getParams(params=nil)
    params = Hash.new if params.blank?
    params["utf8"] = "✓"
    params
  end

end