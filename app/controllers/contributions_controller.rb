class ContributionsController < ApplicationController
  
  before_filter :authenticate_user!
  before_filter :fill_create_params, :only => [:create]
  inherit_resources

  skip_after_filter :discard_flash, :only => [:create]


  #############
  # REST methods
  #############

  def show
    super do |format|
      format.html {
        redirect_to polymorphic_path(resource.activity_object.object, :contribution => true)
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
    end
  end

  def create
    if params["contribution"]["wa_assignment_id"].present?
      wassignment = WaAssignment.find_by_id(params["contribution"]["wa_assignment_id"])
      workshop = wassignment.workshop unless wassignment.nil?
      if wassignment.nil? or workshop.nil?
        flash[:errors] = "Invalid workshop or assignment"
        return redirect_to "/"
      end
    else
      #Get resource from which the contribution is being created...
      parent = Contribution.find_by_id(params["contribution"]["parent_id"])
      if parent.nil?
        flash[:errors] = "Invalid parent"
        return redirect_to "/"
      end
    end

    case params["contribution"]["type"]
    when "Document"
      unless params["document"].present?
        flash[:errors] = "missing document"
        return redirect_to (workshop.nil? ? polymorphic_path(parent) : workshop_path(workshop))
      end
      object = Document.new((params["document"].merge!(params["contribution"]["activity_object"])).permit!)
    when "Writing"
      unless params["writing"].present?
        flash[:errors] = "missing params"
        return redirect_to (workshop.nil? ? polymorphic_path(parent) : workshop_path(workshop))
      end
      object = Writing.new((params["writing"].merge!(params["contribution"]["activity_object"])).permit!)
    else
      flash[:errors] = "Invalid contribution"
      return redirect_to (workshop.nil? ? polymorphic_path(parent) : workshop_path(workshop))
    end

    authorize! :create, object

    object.valid?

    if object.errors.blank? and object.save
      ao = object.activity_object
      discard_flash
    else
      flash[:errors] = object.errors.full_messages.to_sentence
      return redirect_to (workshop.nil? ? polymorphic_path(parent) : workshop_path(workshop))
    end
    
    params["contribution"].delete "activity_object"
    params["contribution"].delete "type"
    params["contribution"]["activity_object_id"] = ao.id

    authorize! :create, Contribution.new(params["contribution"])

    super do |format|
      format.html {
        unless resource.errors.blank?
          flash[:errors] = resource.errors.full_messages.to_sentence
          return redirect_to (workshop.nil? ? polymorphic_path(parent) : workshop_path(workshop))
        else
          discard_flash
          return redirect_to contribution_path(resource)
        end
      }
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