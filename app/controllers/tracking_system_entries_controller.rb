class TrackingSystemEntriesController < ApplicationController

  protect_from_forgery :except => [:index,:create]
  before_filter :authenticate_app, :only => [ :index, :create ]
  skip_load_and_authorize_resource :only => [ :create ]

  # Enable CORS
  before_filter :cors_preflight_check, :only => [:create]
  after_filter :cors_set_access_control_headers, :only => [:create]


  # GET /tracking_system_entries
  # List all tracking_system_entries 
  def index
    @tsentries = TrackingSystemEntry.all
    render :json => @tsentries.to_json
  end

  # POST /tracking_system_entries 
  def create
    return render :json => ["Invalid user agent"] if TrackingSystemEntry.isUserAgentBot?(params[:user_agent])

    tsentry = TrackingSystemEntry.new
    tsentry.app_id = params[:app_id]
    tsentry.user_agent = params[:user_agent]

    unless params[:referrer].blank?
      tsentry.referrer = params[:referrer]
    end

    unless params[:actor_id].blank?
      tsentry.user_logged = true
      unless params[:data].blank?
        params[:data] = fillActorData(params[:data],params[:actor_id])
      end
    end

    unless params[:tracking_system_entry_id].blank?
      tsentry.tracking_system_entry_id = params[:tracking_system_entry_id]
    end

    tsentry.data = params[:data].to_json
    
    if tsentry.save
      render :json => tsentry.to_json
    else
      render :json => ["Generic Tracking System Error"]
    end
  end


  private

  def authenticate_app
    unless Vish::Application.config.APP_CONFIG['trackingSystemAPIKEY'].nil?
      if params[:app_key] != Vish::Application.config.APP_CONFIG['trackingSystemAPIKEY']
        return render :json => ["Unauthorized"], :status => :unauthorized
      end
    end
  end

  def fillActorData(data,actor_id)
    actor = Actor.find_by_id(actor_id)
    unless actor.nil?
      data[:user] = (data[:user] || {})
      data[:user][:age] = actor.profile.age
      data[:user][:country] = actor.profile.country
      data[:user][:city] = actor.profile.city
      data[:user][:tags] = actor.tag_list
      data[:user][:language] = actor.language
      data[:user][:popularity] = actor.popularity
    end
    return data
  end

end