class ScormsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :hack_auth, :only => :create
  include SocialStream::Controllers::Objects

  def create
    super do |format|
      format.json { 
        render :json => resource 
      }
      format.all { 
        redirect_to scorm_path(resource) || home_path 
      }
    end
  end

  def update
    super
  end

  def destroy
    destroy! do |format|
      format.html {
        redirect_to user_path(current_user)
       }
    end
  end

  private

  def allowed_params
    [:fulltext, :width, :height, :live, :language, :age_min, :age_max]
  end

  def hack_auth
    params["scorm"] ||= {}
    params["scorm"]["relation_ids"] = [Relation::Public.instance.id]
    params["scorm"]["owner_id"] = current_subject.actor_id
  end

end

