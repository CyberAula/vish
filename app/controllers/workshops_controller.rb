class WorkshopsController < ApplicationController

  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :contributions]
  before_filter :fill_create_params, :only => [:new, :create]
  before_filter :fill_draft, :only => [:create, :update]
  skip_load_and_authorize_resource :only => [ :edit_details, :contributions ]
  skip_after_filter :discard_flash, :only => [:edit]

  include SocialStream::Controllers::Objects

  #############
  # REST methods
  #############

  def index
    super
  end

  def show
    show! do |format|
      format.html {
        if @workshop.draft and (can? :edit, @workshop)
          redirect_to edit_workshop_path(@workshop)
        else
          # @resource_suggestions = RecommenderSystem.resource_suggestions(current_subject,@excursion,{:n=>16, :models => [Workshop]})
          @workshop_activities = @workshop.workshop_activities.sort_by{ |wa| wa.position }
          render
        end
      }
    end
  end

  def new
    new! do |format|
      format.any {
        render 'new'
      }
    end
  end

  def edit
    edit! do |format|
      format.html {
        @workshop_activities = @workshop.workshop_activities.sort_by{ |wa| wa.position }
        render
      }
    end
  end

  def edit_details
    @workshop = Workshop.find(params[:id])
    authorize! :edit, @workshop

    respond_to do |format|
      format.html
    end
  end

  def create
    super do |format|
      format.html {
        if resource.new_record?
          render action: :new
        else
          redirect_to edit_workshop_path(resource) || home_path
        end
      }
    end
  end

  def update
    if params["workshop_activities_order"]
      begin
        wa_positions = JSON.parse(params["workshop_activities_order"]).map{|p| p.to_i}
        wa_positions.each_with_index do |wa_id, index|
          wa = resource.workshop_activities.find_by_id(wa_id)
          unless wa.nil?
            wa.update_column :position, index+1
          end
        end
      rescue
      end
      params.delete "workshop_activities_order"
    end

    super do |format|
      format.html {
        if resource.draft
          redirect_to edit_workshop_path(resource)
        else
          redirect_to workshop_path(resource)
        end
      }
      format.json {
        render :json => resource
      }
    end
  end

  def contributions
    @workshop = Workshop.find(params[:id])

    unless verify_owner(@workshop)
      return render :text => "You are not the owner of this workshop"
    end

    respond_to do |format|
      format.html {
        @contributions = @workshop.contributions
        render
      }
    end
  end

  def destroy
    destroy! do |format|
      format.all { redirect_to user_path(current_subject) }
    end
  end


  private

  def allowed_params
    [:draft, :language, :age_min, :age_max, :scope, :avatar, :tag_list=>[]]
  end

  def fill_create_params
    params["workshop"] ||= {}

    unless current_subject.nil?
      params["workshop"]["owner_id"] = current_subject.actor_id
      params["workshop"]["author_id"] = current_subject.actor_id
      params["workshop"]["user_author_id"] = current_subject.actor_id
    end
  end

  def fill_draft
    params["workshop"] ||= {}
    
    workshop = resource rescue nil
    if workshop.nil?
      #Creating new workshop
      if params["workshop"]["draft"].blank?
        params["workshop"]["draft"]="true"
      end
    end

    if params["workshop"]["draft"]==="true"
      params["workshop"]["scope"] = "1" #private
      params["workshop"]["draft"] = true
    elsif params["workshop"]["draft"]==="false"
      params["workshop"]["scope"] = "0" #public
      params["workshop"]["draft"] = false
    end
  end

  def verify_owner(workshop)
    return (can? :update, workshop)
  end

end