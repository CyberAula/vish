class RecommenderController < ApplicationController

  skip_load_and_authorize_resource :only => [:api_resource_suggestions]

  # Enable CORS
  before_filter :cors_preflight_check, :only => [:api_resource_suggestions]
  after_filter :cors_set_access_control_headers, :only => [:api_resource_suggestions]


  ##################
  # API REST
  ##################
  def api_resource_suggestions
    current_resource =  ActivityObject.find_by_id(params[:resource_id]).object rescue nil if params[:resource_id]
    n = 12 #TODO. Get n from parameters.
    resources = RecommenderSystem.resource_suggestions({:user => current_subject, :lo => current_resource, :n => n})
    respond_to do |format|
      format.any { 
        render :json => resources.map {|r| r.activity_object.search_json(self) }, :content_type => "application/json"
      }
    end
  end

end