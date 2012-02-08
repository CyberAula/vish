class FollowController < ApplicationController
  before_filter :authenticate_user!
  before_filter :exclude_reflexive, :except => [ :index, :followers, :followings ]

  respond_to :html, :js

  def new
    # TODO: Create contact and do some more stuff, maybe at model?
  end

  def create
  end

  def index
    followers
  end

  def followers
    @followers = contacts_followers

    respond_to do |format|
      format.html { @followers = @followers.page(params[:page]).per(20) }
      format.js { @followers = @followers.page(params[:page]).per(20) }
      format.json { render :text => to_json(@followers) }
    end
  end

  def followings
    @followings = contacts_followings

    respond_to do |format|
      format.html { @followings = @followings.page(params[:page]).per(20) }
      format.js { @followings = @followings.page(params[:page]).per(20) }
      format.json { render :text => to_json(@followings) }
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
    @follower = current_subject.received_contacts.find params[:id] # These are nil if the contact is not following / being followed
    @following = current_subject.sent_contacts.find params[:id]

    if ( not @follower.nil? and @follower.reflexive? ) or ( not @following.nil? and @following.reflexive? )
      redirect_to home_path
    end
  end

  def contacts_followers
    current_subject.received_contacts
  end

  def contacts_following
    current_subject.sent_contacts
  end

end
