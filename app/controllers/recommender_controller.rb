class RecommenderController < ApplicationController

  skip_load_and_authorize_resource :only => [:api_resource_suggestions]

  # Enable CORS
  before_filter :cors_preflight_check, :only => [:api_resource_suggestions]
  after_filter :cors_set_access_control_headers, :only => [:api_resource_suggestions]


  ##################
  # API REST
  ##################
  def api_resource_suggestions
    if params[:resource_id]
      current_resource =  ActivityObject.find(params[:resource_id]).object rescue nil
    end
    resources = RecommenderSystem.resource_suggestions(current_subject,current_resource)
    respond_to do |format|
      format.any { 
        results = []
        resources.map { |r| results.push(r.activity_object.search_json(self)) }
        render :json => results, :content_type => "application/json"
      }
    end
  end

end