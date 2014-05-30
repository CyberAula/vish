class UsersController < ApplicationController
  include SocialStream::Controllers::Subjects

  load_and_authorize_resource :except => [:current, :resources, :events, :categories, :followers, :followings]

  before_filter :authenticate_user!, only: :current

  respond_to :html, :xml, :js
  
  def index
    raise ActiveRecord::RecordNotFound
  end

  def show
    show! do |format|
      format.html{
        if !params[:page]
          render "show"
        else
          render :partial => "excursions/excursions", :locals => {:scope => :me, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
        end
      }
    end
  end

  def resources
    respond_to do |format|
      format.html{        
        render :partial => 'repositories/resources', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
      }
    end
  end

  def events
    respond_to do |format|
      format.html{        
        render :partial => 'events/events', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
      }
    end
  end

  def categories
    respond_to do |format|
      format.html{        
        render :partial => 'categories/categories', :locals => {:scope => :me, :limit => 0, :page=> params[:page]||1, :sort_by=> params[:sort_by]||"updated_at"}, :layout => false
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

  # Supported through devise
  def new; end; def create; end
  # Not supported yet
  def destroy; end
end
