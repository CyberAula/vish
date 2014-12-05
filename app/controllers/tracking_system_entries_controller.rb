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
    tsentry = TrackingSystemEntry.new
    tsentry.app_id = params[:app_id]
    unless params[:data].nil?
      params[:data] = fillUserData(params[:data])
    end
    tsentry.data = params[:data].to_json
    
    if tsentry.save
      render :json => tsentry.to_json
    else
      render :json => ["Tracking System Error"]
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

  def fillUserData(data)
    if !data[:user].nil? and !data[:user][:id].nil?
      user = User.find(data[:user][:id]) rescue nil
      if !user.nil?
        data[:user][:age] = user.profile.age
        data[:user][:country] = user.profile.country
        data[:user][:city] = user.profile.city
        data[:user][:tags] = user.tag_list
        data[:user][:language] = user.language
        data[:user][:popularity] = user.popularity
      end
    end
    return data
  end

end