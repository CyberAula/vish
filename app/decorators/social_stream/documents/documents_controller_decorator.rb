DocumentsController.class_eval do

  before_filter :fill_create_params, :only => [:new, :create]

  # Enable CORS
  before_filter :cors_preflight_check, :only => [:show]
  after_filter :cors_set_access_control_headers, :only => [:show]
  after_filter :notify_teacher, :only => [:create, :update]

  def create
    super do |format|
      #Check if the Zipfile contains a Web Application or a SCORM Package to create the new resource and redirect to it.
      if resource.is_a? Zipfile
        newResource = resource.getResourceAfterSave
        if newResource.is_a? String
          #Raise error
          flash.now[:alert] = newResource
          render action: :new
        else
          if params["format"] == "json"
            render :json => newResource.to_json(helper: self), status: :created
          else
            redirect_to newResource
          end
        end
        return
      end
      
      format.json {
        jsonResult = resource.to_json(helper: self)
        if params["preferred_conversion"]=="avatar" and resource.is_a? Picture
          parsedJsonResult = JSON(jsonResult)
          parsedJsonResult["src"] += "?style=500"
          jsonResult = parsedJsonResult.to_json
        end
        render :json => jsonResult, status: :created
      }
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
    [:file, :language, :license_id, :original_author, :license_attribution, :license_custom, :age_min, :age_max, :scope, :avatar, :tag_list=>[]]
  end

  def fill_create_params
    params["document"] ||= {}
    params["document"]["scope"] ||= "0" #public
    params["document"]["owner_id"] = current_subject.actor_id
    params["document"]["author_id"] = current_subject.actor_id
    params["document"]["user_author_id"] = current_subject.actor_id
  end

  def notify_teacher    
    if VishConfig.getAvailableServices.include? "PrivateStudentGroups"
      author_id = resource.author.user.id rescue nil
      unless author_id.nil?
        pupil = resource.author.user
        if !pupil.private_student_group_id.nil? && pupil.private_student_group.teacher_notification == "ALL"
          teacher = Actor.find(pupil.private_student_group.owner_id).user
          resource_path = document_path(resource) #TODO get full path
          TeacherNotificationMailer.notify_teacher(teacher, pupil, resource_path)
        end
      end
    end
  end
  
end
