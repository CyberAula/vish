class UsersController < ApplicationController
  include SocialStream::Controllers::Subjects

  load_and_authorize_resource :except => [:current]

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

  def excursions
    respond_to do |format|
      format.html{        
        if !params[:page] || params[:tab] == "excursions" || (params[:page] && (params[:page] == 1 || params[:page]==0))
          render :partial => 'excursions/profile_excursions', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'excursions/excursions_profile', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def workshops
    respond_to do |format|
      format.html{        
        if !params[:page] || params[:tab] == "workshops" || (params[:page] && (params[:page] == 1 || params[:page]==0))
          render :partial => 'workshops/profile_workshops', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'workshops/workshops_profile', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def resources
    respond_to do |format|
      format.html{        
        if !params[:page] || params[:tab] == "resources" || (params[:page] && (params[:page] == 1 || params[:page]==0))
          render :partial => 'repositories/profile_resources', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'repositories/resources', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def events
    respond_to do |format|
      format.html{       
        if !params[:page] || params[:tab] == "events" || (params[:page] && (params[:page] == 1 || params[:page]==0)) 
          render :partial => 'events/profile_events', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        else
          render :partial => 'events/events', :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def categories
    respond_to do |format|
      format.html{
        #Categories do not have pageless
        render :partial => 'categories/profile_categories', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
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

  #Make user admin
  def promote
    u = User.find_by_slug(params[:id])
    authorize! :make_admin, u

    u.make_me_admin

    redirect_to user_path(u)
  end

  #Degrade admin to user
  def degrade
    u = User.find_by_slug(params[:id])
    authorize! :make_admin, u
    
    u.degrade

    redirect_to user_path(u)
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
