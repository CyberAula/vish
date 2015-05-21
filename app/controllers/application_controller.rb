class ApplicationController < ActionController::Base
  protect_from_forgery
  include SimpleCaptcha::ControllerHelpers
  before_filter :store_location
  after_filter :discard_flash

  def discard_flash
  	flash.discard # don't want the flash to appear when you reload page
  end

  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || session[:user_return_to] || root_path
  end
  
  # Store last url. This filter is used for post-login redirect to whatever the user last visited.
  def store_location
    if (
      request.get? && #only store get requests
      request.format == "text/html" &&   #if the user asks for a specific resource .jpeg, .png etc do not redirect to it
      !request.xhr? # don't store ajax calls
    )
      session[:user_return_to] = request.fullpath
    end
  end

  def discard_location
    session[:user_return_to] = root_path
  end

  #Method used for skip store_location in the corresponding controllers.
  #Prevent .full urls to be saved as valid locations to return after sign in.
  def format_full?
    params["format"]=="full"
  end

  #############
  # CORS
  # Methods to enable CORS (http://www.tsheffler.com/blog/?p=428)
  #############

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method.downcase.to_sym == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

end
