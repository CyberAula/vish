DocumentsController.class_eval do

  before_filter :fill_create_params, :only => [:new, :create]


  def create
    resource.relation_ids = params["document"]["relation_ids"] if params["document"]["relation_ids"].present?

    super do |format|
      if resource.is_a? Zipfile
        newResource = resource.getResourceAfterSave(self)
        if newResource.is_a? String
          #Raise error
          flash.now[:alert] = newResource
          render action: :new
        else
          if params["format"] == "json"
            render :json => newResource.as_json, status: :created
          else
            redirect_to newResource
          end
        end
        return
      end
      
      format.json { render :json => resource.to_json(helper: self), status: :created }
      format.js
      format.all {
        if resource.new_record?
          render action: :new
        elsif params["document"]["add_holder_event_id"]
          redirect_to request.referer #we are adding poster to an event, redirect to the event
        else
          redirect_to resource
        end
      }
    end
  end

  def update
    update! do |success, failure|
      failure.html { render :action => :show }
      success.html {
        if params[:controller] == "pictures"
          redirect_to request.referer
        else
          render :action => :show 
        end
      }
    end
  end

  def destroy
    super do |format|
      format.html {
        redirect_to url_for(current_subject)
      }

      format.js
    end
  end


  private

  def allowed_params
    [:file, :language, :age_min, :age_max, :tag_list=>[]]
  end

  def fill_create_params
    params["document"] ||= {}

    if params["document"]["scope"].is_a? String
      case params["document"]["scope"]
      when "public"
        params["document"]["relation_ids"] = [Relation::Public.instance.id]
      when "private"
        params["document"]["relation_ids"] = [Relation::Private.instance.id]
      end
      params["document"].delete "scope"
    end

    unless params["document"]["relation_ids"].present?
      #Public by default
      params["document"]["relation_ids"] = [Relation::Public.instance.id]
    end
    
    params["document"]["owner_id"] = current_subject.actor_id
    params["document"]["author_id"] = current_subject.actor_id
    params["document"]["user_author_id"] = current_subject.actor_id
  end

end
