class ApplicationController < ActionController::Base
  protect_from_forgery
  include SimpleCaptcha::ControllerHelpers
  before_filter :store_location
  after_filter :discard_flash
  before_filter :set_locale
  before_filter :check_fb_locale


  #############
  # Devise
  #############
  def after_sign_in_path_for(resource)
    request.env['omniauth.origin'] || session[:user_return_to] || root_path
  end


  #############
  # Last location handling
  #############
  # Store last url. This filter is used for post-login redirect to whatever the user last visited.
  def store_location
    if (
      request.get? && #only store get requests
      request.format == "text/html" &&   #if the user asks for a specific resource .jpeg, .png etc do not redirect to it
      !request.xhr? && # don't store ajax calls
      request.path_info != "/users/service"  #for CAS authentication avoid ERR_TOO_MANY_REDIRECTS
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
    ["full","fs"].include? params["format"]
  end


  #############
  # Other utils
  #############

  def discard_flash
    flash.discard # don't want the flash to appear when you reload page
  end

  def check_fb_locale
    if params[:fb_locale].present?
      fb_locale = params[:fb_locale][0..1] #only the first two characters because it is like "en_GB" and we need only "en"
      I18n.locale = fb_locale if I18n.available_locales.include? fb_locale.to_sym
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


  #############
  # User Locale
  #############
  def set_locale
    I18n.locale = extract_locale_from_params || extract_locale_from_user || extract_locale_from_session || extract_locale_from_accept_language_header || I18n.default_locale
  end


  private

  def extract_locale_from_params
    params[:locale] if params[:locale].present? and I18n.available_locales.include? params[:locale].to_sym
  end

  def extract_locale_from_user
    current_user.language if user_signed_in?
  end

  def extract_locale_from_session
    session[:locale] if session and session[:locale] and I18n.available_locales.include? session[:locale].to_sym
  end

  def extract_locale_from_accept_language_header
    (request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).map{|l| l.to_sym} & I18n.available_locales).first if request.env['HTTP_ACCEPT_LANGUAGE'].is_a? String
  end

end
