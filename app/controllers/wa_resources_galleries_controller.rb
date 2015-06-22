class WaResourcesGalleriesController < ApplicationController

  before_filter :authenticate_user!
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

  def update
    ao_ids = resource.activity_object_ids

    unless params["url"].blank?
      the_resource = ActivityObject.getObjectFromUrl(params["url"])
      unless the_resource.nil? or the_resource.activity_object.nil?
        ao_ids << the_resource.activity_object.id
      end
    end

    unless params["remove_activity_object_id"].blank?
      ao_ids.reject!{|id| id.to_s==params["remove_activity_object_id"]}
    end

    ao_ids.uniq!
    resource.activity_object_ids = ao_ids

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

  def add_resource
    resource = WaResourcesGallery.find(params[:id])
    respond_to do |format|
      format.html {
        render :form_add_resource, :layout => false
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
    [:workshop_id, :activity_object_ids=>[]]
  end

end