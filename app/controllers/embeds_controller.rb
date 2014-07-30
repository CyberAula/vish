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
    [:fulltext, :width, :height, :live, :language, :age_min, :age_max]
  end

  def fill_create_params
    params["embed"] ||= {}

    if params["embed"]["scope"].is_a? String
      case params["embed"]["scope"]
      when "public"
        params["embed"]["relation_ids"] = [Relation::Public.instance.id]
      when "private"
        params["embed"]["relation_ids"] = [Relation::Private.instance.id]
      end
      params["embed"].delete "scope"
    end

    unless params["embed"]["relation_ids"].present?
      #Public by default
      params["embed"]["relation_ids"] = [Relation::Public.instance.id]
    end
    
    params["embed"]["owner_id"] = current_subject.actor_id
    params["embed"]["author_id"] = current_subject.actor_id
    params["embed"]["user_author_id"] = current_subject.actor_id
  end
end

