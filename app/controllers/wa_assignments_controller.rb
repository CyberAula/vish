class WaAssignmentsController < ApplicationController

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
    super do |format|
      format.html {
        if request.xhr?
          #Ajax call
          unless resource.errors.blank?
            render :json => {errors: [resource.errors.full_messages.to_sentence]}
          else
            render :json => {errors: []}
          end
        else
          unless resource.errors.blank?
            flash[:errors] = resource.errors.full_messages.to_sentence
          else
            discard_flash
          end
          redirect_to edit_workshop_path(resource.workshop, {:activity => resource.workshop_activity.id})
        end
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
    [:workshop_id, :fulltext, :open_date, :due_date]
  end

end