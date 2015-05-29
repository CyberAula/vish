LinksController.class_eval do

  before_filter :fill_create_params, :only => [:new, :create]

  def create
    super do |format|
      format.json {
        render :json => resource 
      }
      format.js
      format.all {
        if resource.new_record?
          render action: :new
        else
          redirect_to link_path(resource) || url_for(current_subject)
        end
      }
  	end
  end


  private

  def allowed_params
    [:url, :image, :callback, :width, :height, :callback_url, :loaded, :language, :license_id, :age_min, :age_max, :scope, :avatar, :tag_list=>[]]
  end

  def fill_create_params
    params["link"] ||= {}
    params["link"]["scope"] ||= "0" #public
    params["link"]["owner_id"] = current_subject.actor_id
    params["link"]["author_id"] = current_subject.actor_id
    params["link"]["user_author_id"] = current_subject.actor_id
  end
  
end
