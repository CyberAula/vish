class LiveSessionsController < ApplicationController
  before_filter :authenticate_user!, :only => [ :create, :destroy ]
  before_filter :profile_subject!, :only => :actor

  def create # POST /live_sessions => open live session for current user
    e=Excursion.find(params[:excursion_id])
    ls=LiveSession.find_by_user_id(current_user.id)
    if ls.blank?
      ls=LiveSession.new({ :user => current_user, :excursion => e})
    else
      ls.excursion=e
    end
    ls.save!
    render :json => ls
  end

  def destroy # DELETE /live_sessions => destroy live session for current user
    ls=LiveSession.find_by_user_id(current_user.id)
    ls.destroy
    render :json => []
  end

  def actor
    ls=LiveSession.find_by_user_id(profile_subject.user.id)
    render 'live_sessions/error' if ls.blank?
    @excursion=ls.excursion
    render 'excursions/show', :formats => ['full'], :layout => 'iframe'
  end
end
