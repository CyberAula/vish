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
	  # store last url - this is needed for post-login redirect to whatever the user last visited.
	  if (request.fullpath != "/users/sign_in" &&
	      request.fullpath != "/users/sign_up" &&
	      request.fullpath != "/users/sign_out" &&
	      request.fullpath != "/users/password" &&
	      request.fullpath != "/users/password/new" &&
	      request.fullpath != "/users" &&
	      request.format == "text/html" &&   #if the user asks for a specific resource .jpeg, .png etc do not redirect to it
	      !request.fullpath.end_with?(".full") &&   #do not save .full because we have saved the vish excursion page instead
	      !request.xhr?) # don't store ajax calls
	    session[:user_return_to] = request.fullpath 
	  end
  end

end
