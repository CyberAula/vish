# encoding: utf-8

class Loep::SessionTokenController < ApplicationController
  protect_from_forgery :except => [:index,:create]

  # before_filter :authenticate_user! #Allow anonymous evaluations
  
  # Enable CORS
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers
  
  ###########
  # CORS
  ###########
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

  ###########
  # API REST for Create Session Tokens
  ###########

  def index
    create
  end

  # POST /loep/session_token
  def create
    Loep.createSessionToken(){|auth_token,c|
      render :json => {auth_token: auth_token}, :content_type => "application/json"
    }
  end

end