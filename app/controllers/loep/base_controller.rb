class Loep::BaseController < ActionController::Base

  #################
  # Authentication for LOEP
  ################

  def authenticate_app
    if params["repository_name"].nil? or params["auth_token"].nil?
      render :json => ["Unauthorized"], :status => :unauthorized
      return
    end

    if params["repository_name"]!="ViSH" or params["auth_token"] != Vish::Application.config.loep_token
      render :json => ["Unauthorized"], :status => :unauthorized
      return
    end
  end

end