class EmbedsController < ApplicationController
  before_filter :authenticate_user!, :only => [ :create, :update ]
  before_filter :fill_create_params, :only => [:new, :create]
  include SocialStream::Controllers::Objects


  def create
    super do |format|
      format.json { render :json => resource }
      format.js{ render }
      format.all {redirect_to embed_path(resource) || home_path}
    end
  end

  def update
    super
  end

  def destroy
    destroy! do |format|
      format.html {
        redirect_to url_for(current_subject)
       }
    end
  end


  private

  def allowed_params
    [:fulltext, :width, :height, :live, :language, :age_min, :age_max, :scope]
  end

  def fill_create_params
    params["embed"] ||= {}
    params["embed"]["scope"] ||= "0" #public
    params["embed"]["owner_id"] = current_subject.actor_id
    params["embed"]["author_id"] = current_subject.actor_id
    params["embed"]["user_author_id"] = current_subject.actor_id
  end
end

