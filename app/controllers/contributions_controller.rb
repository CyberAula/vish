class ContributionsController < ApplicationController

  before_filter :authenticate_user!, :except => [:show]
  before_filter :fill_create_params, :only => [:create]
  inherit_resources

  skip_after_filter :discard_flash, :only => [:create]


  #############
  # REST methods
  #############

  def show
    super do |format|
      format.html {
        redirect_to polymorphic_path(resource.activity_object.object, :contribution => resource.id)
      }
    end
  end

  def new
    super do |format|
      format.html {
        if params[:type]
          render "new_" + params[:type]
        else
          render "new"
        end
      }
      format.partial {
        render :new, :layout => false
      }
    end
  end

  def create
    if params["contribution"]["wa_assignment_id"].present?
      wassignment = WaAssignment.find_by_id(params["contribution"]["wa_assignment_id"])
      workshop = wassignment.workshop unless wassignment.nil?
      return create_return_with_error("Invalid workshop or assignment","/") if wassignment.nil? or workshop.nil?
    else
      #Get resource from which the contribution is being created...
      parent = Contribution.find_by_id(params["contribution"]["parent_id"])
      return create_return_with_error("Invalid parent","/") if parent.nil?
    end
    pathToReturn = (workshop.nil? ? polymorphic_path(parent) : workshop_path(workshop))

    case params["contribution"]["type"]
    when "Document"
      return create_return_with_error("missing document",pathToReturn) unless params["document"].present?
      object = Document.new((params["document"].merge!(params["contribution"]["activity_object"])).permit!)
    when "Writing"
      return create_return_with_error("missing params",pathToReturn) unless params["writing"].present?
      object = Writing.new((params["writing"].merge!(params["contribution"]["activity_object"])).permit!)
    when "Resource"
      return create_return_with_error(I18n.t("contribution.messages.url_not_found"),pathToReturn) unless params["url"].present?
      object = ActivityObject.getObjectFromUrl(params["url"])
      return create_return_with_error(I18n.t("contribution.messages.object_not_found"),pathToReturn) if object.nil?
    else
      return create_return_with_error("Invalid contribution type",pathToReturn)
    end
    
    if object.new_record?
      #We need to create and save the object
      authorize! :create, object
      object.valid?
      return create_return_with_error(object.errors.full_messages.to_sentence,pathToReturn) unless object.errors.blank? and object.save
      discard_flash
    else
      #Object already exists. Authorize user to submit that object.
      return create_return_with_error(I18n.t("contribution.messages.object_not_yours"),pathToReturn) unless object.owner_id == current_subject.actor_id
      authorize! :update, object
    end

    ao = object.activity_object
    params["contribution"]["activity_object_id"] = ao.id
    params["contribution"].delete "activity_object"
    params["contribution"].delete "type"
    authorize! :create, Contribution.new(params["contribution"])

    super do |format|
      format.any {
        return create_return_with_error(resource.errors.full_messages.to_sentence,pathToReturn) unless resource.errors.blank?
        #Return with success
        if request.xhr?
          return render :json => {}, :status => 200
        else
          discard_flash
          return redirect_to contribution_path(resource)
        end
      }
    end
  end

  def create_return_with_error(error,pathToReturn)
    if request.xhr?
      return render :json => {errors: [error]}, :status => 400
    else
      flash[:errors] = error
      return redirect_to pathToReturn
    end
  end


  private

  def allowed_params
    [:wa_assignment_id, :activity_object_id]
  end

  def fill_create_params
    params["contribution"] ||= {}
    params["contribution"]["activity_object"] ||= {}
    params["contribution"]["activity_object"]["scope"] = "1" #private
    unless current_subject.nil?
      params["contribution"]["activity_object"]["owner_id"] = current_subject.actor_id
      params["contribution"]["activity_object"]["author_id"] = current_subject.actor_id
      params["contribution"]["activity_object"]["user_author_id"] = current_subject.actor_id
    end
  end

end
