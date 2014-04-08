DocumentsController.class_eval do

  def allowed_params
    [:file, :language, :age_min, :age_max, :tag_list=>[]]
  end
  
  def create
    super do |format|
      if resource.is_a? Zipfile
        newResource = resource.getResourceAfterSave(self)
        if newResource.is_a? String
          #Raise error
          flash.now[:alert] = newResource
          render action: :new
        else
          redirect_to newResource
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
        redirect_to current_user
      }

      format.js
    end
  end

end
