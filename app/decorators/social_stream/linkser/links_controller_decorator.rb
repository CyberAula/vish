LinksController.class_eval do

  before_filter :fill_create_params, :only => [:new, :create]
  after_filter :notify_teacher, :only => [:create]
  
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
  
  def notify_teacher
    if VishConfig.getAvailableServices.include? "PrivateStudentGroups"
      author_id = resource.author.user.id
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
