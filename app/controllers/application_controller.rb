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
  
  def store_location
    urls_to_avoid_redirect = ["/users/sign_in","/users/sign_up","/users/sign_out","/users/password","/users/password/new","/users","/legal_notice"]

    # store last url - this is needed for post-login redirect to whatever the user last visited.
    if ((!urls_to_avoid_redirect.include? request.fullpath) &&
    request.format == "text/html" &&   #if the user asks for a specific resource .jpeg, .png etc do not redirect to it
    !request.fullpath.end_with?(".full") &&   #do not save .full because we have saved the vish excursion page instead
    !request.xhr?) # don't store ajax calls
      session[:user_return_to] = request.fullpath
    end
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
