class UsersController < ApplicationController
  include SocialStream::Controllers::Subjects

  load_and_authorize_resource except: :current

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
          render :partial => "excursions/excursions", :locals => {:scope => :net, :limit => 0, :page=> params[:page], :sort_by=> params[:sort_by]||"popularity"}, :layout => false
        end
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
