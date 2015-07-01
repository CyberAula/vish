class UsersController < ApplicationController
  include SocialStream::Controllers::Subjects

  load_and_authorize_resource :except => [:current, :update_role]

  before_filter :authenticate_user!, only: :current

  respond_to :html, :xml, :js
  
  def index
    raise ActiveRecord::RecordNotFound
  end

  def show
    show! do |format|
      format.html{
        render "show"
      }
    end
  end

  def edit
    redirect_to user_path(resource)
  end

  def edit_role
    authorize! :edit_roles, resource
  end

  def update_role
    authorize! :edit_roles, resource

    user_was_admin = resource.admin?
    role = Role.find(params["role"]) rescue nil
    unless role.nil?
      resource.roles = [role]
    end
    user_is_admin = resource.admin?

    if !user_was_admin and user_is_admin
      #promote
      resource.make_me_admin
    elsif user_was_admin and !user_is_admin
      #degrade
      resource.degrade
    end

    redirect_to user_path(resource)
  end

  def excursions
    respond_to do |format|
      format.html{        
        if !params[:page] || params[:tab] == "excursions" || (params[:page] && (params[:page] == 1))
          render :partial => 'excursions/profile_excursions_list', :locals => {:scope => :me, :limit => 0, :page=> 1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'excursions/profile_excursions_page', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def workshops
    respond_to do |format|
      format.html{        
        if !params[:page] || params[:tab] == "workshops" || (params[:page] && (params[:page] == 1))
          render :partial => 'workshops/profile_workshops_list', :locals => {:scope => :me, :limit => 0, :page=> 1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'workshops/profile_workshops_page', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def resources
    respond_to do |format|
      format.html{        
        if !params[:page] || params[:tab] == "resources" || (params[:page] && (params[:page] == 1))
          render :partial => 'repositories/profile_resources_list', :locals => {:scope => :me, :limit => 0, :page=> 1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'repositories/profile_resources_page', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def events
    respond_to do |format|
      format.html{       
        if !params[:page] || params[:tab] == "events" || (params[:page] && (params[:page] == 1)) 
          render :partial => 'events/profile_events_list', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'events/profile_events_page', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def categories
    respond_to do |format|
      format.html{
        #Categories do not have pageless
        render :partial => 'categories/profile_categories_list', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
      }
    end
  end

  def followers
    respond_to do |format|
      format.html{        
        render partial: 'users/user', collection: profile_or_current_subject.followers, :layout => false
      }
    end
  end

  def followings
    respond_to do |format|
      format.html{        
        render partial: 'users/user', collection: profile_or_current_subject.followings.where(object_type: 'Actor').includes(:actor).map(&:actor), :layout => false
      }
    end
  end

  def current
    respond_to do |format|
      format.json { render json: current_user.to_json }
    end
  end

  def destroy
    u = User.find_by_slug(params[:id])
    authorize! :destroy, u

    unless u.nil?
      u.destroy
    end

    respond_to do |format|
      format.any {
        if !request.referrer.nil? and request.referrer.include?("/admin/users")
          redirect_to admin_users_path
        else
          #Only admins can destroy users. Redirect to home.
          redirect_to home_path
        end
      }
    end
  end

  # Supported through devise
  def new; end; def create; end

end
