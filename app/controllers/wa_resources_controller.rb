class WaResourcesController < ApplicationController

  before_filter :authenticate_user!
  before_filter :fill_create_params, :only => [:create, :update]
  inherit_resources

  load_and_authorize_resource
  skip_after_filter :discard_flash, :only => [:create, :update]

  #############
  # REST methods
  #############

  def create
    super do |format|
      format.html {
        unless resource.errors.blank?
          flash[:errors] = resource.errors.full_messages.to_sentence
        else
          discard_flash
        end
        
        redirect_to edit_workshop_path(resource.workshop, {:activity => resource.workshop_activity.id})
      }
    end
  end

  def edit
    if params["format"]=="partial"
      super do |format|
        format.partial
      end
    end
  end

  def update   
    super do |format|
      format.html {
        unless resource.errors.blank?
          flash[:errors] = resource.errors.full_messages.to_sentence
        else
          discard_flash
        end
        redirect_to edit_workshop_path(resource.workshop, {:activity => resource.workshop_activity.id})
      }
    end
  end

  def destroy
    destroy! do |format|
      format.all {
        redirect_to edit_workshop_path(resource.workshop) 
      }
    end
  end


  private

  def allowed_params
    [:workshop_id, :activity_object_id]
  end

  def fill_create_params
    params["wa_resource"] ||= {}
    params["wa_resource"]["activity_object_id"] = -1
    
    unless params["url"].blank?
      the_resource = ActivityObject.getObjectFromUrl(params["url"])
      unless the_resource.nil? or the_resource.activity_object.nil?
        params["wa_resource"]["activity_object_id"] = the_resource.activity_object.id
      end
    end
  end

end