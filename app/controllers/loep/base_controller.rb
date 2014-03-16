class Loep::BaseController < ActionController::Base

  #################
  # Authentication for LOEP
  ################

  def authenticate_app
    if params["app_name"].nil? or params["auth_token"].nil?
      render :json => ["Unauthorized"], :status => :unauthorized
      return
    end

    if params["app_name"]!="ViSH" or params["auth_token"] != Vish::Application.config.loep_token
      render :json => ["Unauthorized"], :status => :unauthorized
      return
    end
  end

end