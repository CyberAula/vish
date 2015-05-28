# encoding: utf-8

class WappAuthTokensController < ApplicationController
  protect_from_forgery :except => [:index,:create]

  before_filter :authenticate_user!, :only => [:create]
  
  # Enable CORS for all methods
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  ###########
  # API REST for Create Session Tokens for Web Applications
  ###########

  # GET '/apis/wapp_token/auth_token'
  def show
    r = {error: "Token not valid"}

    unless params["auth_token"].nil?
      token = WappAuthToken.find_by_auth_token(params["auth_token"])
      unless token.nil? or token.expired?
        r = {}
        r["token"] = token.auth_token
        r["username"] = token.actor.name
        r["role"] = (token.actor.admin?) ? "Admin" : "User"
      end
    end

    render :json => r, :content_type => "application/json"
  end

  # GET '/apis/wapp_token'
  def create
    token = WappAuthToken.new
    token.actor_id = current_subject.actor_id
    token.save!
    render :json => {auth_token: token.auth_token}, :content_type => "application/json"
  end

end