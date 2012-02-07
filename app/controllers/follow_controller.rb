class FollowController < ApplicationController
  before_filter :authenticate_user!
  before_filter :exclude_reflexive, :except => :index
  load_and_authorize_resource :class => Relation::Follow

  respond_to :html, :js

  def index
    @followers = followers.all
    @following = following.all

    respond_to do |format|
      format.html { @followers = @followers.page(params[:page]).per(10) }
      format.js { @followers = @followers.page(params[:page]).per(10) }
      format.json { render :text => to_json(@followers) }
    end
  end

  def edit
  end

  def update
  end

  def destroy
    
  end

  private

  def exclude_reflexive
    @contact = current_subject.sent_contacts.find params[:id]

    if @contact.reflexive?
      redirect_to home_path
    end
  end

  def followers
    current_subject.received_contacts
  end

  def following
    current_subject.sent_contacts
  end

end
