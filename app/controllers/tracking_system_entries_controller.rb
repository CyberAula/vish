class TrackingSystemEntriesController < ApplicationController

  before_filter :authenticate_app, :only => [ :index, :create ]

  # Enable CORS
  before_filter :cors_preflight_check, :only => [ :create ]
  after_filter :cors_set_access_control_headers, :only => [ :create ]


  # GET /tracking_system_entries
  # List all tracking_system_entries 
  def index
    @tsentries = TrackingSystemEntry.all
    render :json => @tsentries.to_json
  end

  # POST /tracking_system_entries 
  def create
    tsentry = TrackingSystemEntry.new(params[:tracking_system_entry])
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

  #############
  # CORS
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
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

end