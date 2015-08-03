# encoding: utf-8
require 'base64'

class Loep::BaseController < ActionController::Base

  #################
  # Authentication for LOEP
  # HTTP Basic Authentication
  ################

  def authenticate_app
    begin
      authHeader = request.headers["HTTP_AUTHORIZATION"]
      credentials = Base64.decode64(authHeader[6..-1]).split(":")
      unless (authHeader[0,6]==="Basic " && credentials[0]==Vish::Application.config.APP_CONFIG['loep']['app_name'] &&  credentials[1]==Vish::Application.config.APP_CONFIG['loep']['auth_token'])
        return render :json => ["Unauthorized"], :status => :unauthorized
      end
    rescue
      return render :json => ["Unauthorized"], :status => :unauthorized
    end
  end

end