LinksController.class_eval do

  before_filter :fill_create_params, :only => [:new, :create]


  def create
    resource.relation_ids = params["link"]["relation_ids"] if params["link"]["relation_ids"].present?

    super do |format|
      format.json { render :json => resource }
      format.js { render }
      format.all {redirect_to link_path(resource) || url_for(current_subject)}
  	end
  end


  private

  def allowed_params
    [:url, :image, :callback, :width, :height, :callback_url, :loaded, :language, :age_min, :age_max, :tag_list=>[]]
  end

  def fill_create_params
    params["link"] ||= {}

    if params["link"]["scope"].is_a? String
      case params["link"]["scope"]
      when "public"
        params["link"]["relation_ids"] = [Relation::Public.instance.id]
      when "private"
        params["link"]["relation_ids"] = [Relation::Private.instance.id]
      end
      params["link"].delete "scope"
    end

    unless params["link"]["relation_ids"].present?
      #Public by default
      params["link"]["relation_ids"] = [Relation::Public.instance.id]
    end
    
    params["link"]["owner_id"] = current_subject.actor_id
    params["link"]["author_id"] = current_subject.actor_id
    params["link"]["user_author_id"] = current_subject.actor_id
  end
  
end
