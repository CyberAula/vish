class FollowersController < ApplicationController
  before_filter :profile_subject!, :only => :index
  before_filter :authenticate_user!, :except => :index

  respond_to :html, :js

  def search_followers
    headers['Last-Modified'] = Time.now.httpdate

    # TODO params[:page]  /  params[:per_page]
    @found_followers = search_subject.followers.where("name LIKE (?)", "%#{params[:q]}%").order("created_at DESC").limit(20)
    respond_to do |format|
      format.html { render :layout => false }
      format.json { render :json => @found_followers }
    end
  end

  def search_followings
    headers['Last-Modified'] = Time.now.httpdate

    # TODO params[:page]  /  params[:per_page]
    @found_followings = search_subject.followings.joins(:actor).where("actors.name LIKE (?)", "%#{params[:q]}%").order("created_at DESC").limit(20)

    respond_to do |format|
      format.html { render :layout => false }
      format.json { render :json => @found_followings }
    end
  end

  def index
    @followings = profile_or_current_subject.following_actor_objects.includes(:actor)
    @followers = profile_or_current_subject.followers

    respond_to do |format|
      format.html
      format.json { render :text => to_json(@followers) }
    end
  end

  def update
    current_contact.relation_ids = Array.wrap(Relation::Follow.instance.id)

    respond_to :js
  end

  def destroy
    current_contact.relation_ids = Array.new

    respond_to :js
  end

  private

  def search_subject
    @search_subject ||=
      ( Actor.find_by_slug(URI(request.referer).path.split("/")[2]) || current_subject )
  end

  def current_contact
    @contact ||=
      current_subject.sent_contacts.find params[:id]
  end
end
