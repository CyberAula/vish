LinksController.class_eval do

  before_filter :fill_create_params, :only => [:new, :create]
  after_filter :notify_teacher, :only => [:create]
  skip_after_filter :discard_flash, :only => [:create, :update]

  def show
    super do |format|
      format.json {
        render :json => resource
      }
    end
  end

  def create
    super do |format|
      format.json {
        render :json => resource
      }
      format.js
      format.all {
        if resource.new_record?
          if lookup_context.template_exists?("new", "links", false)
            render action: :new
          else
            unless resource.errors.blank?
              if resource.errors[:url].present?
                flash[:errors] = I18n.t("link.messages.url_blank")
              elsif resource.errors[:title].present?
                flash[:errors] = I18n.t("link.messages.title_blank")
              else
                flash[:errors] = resource.errors.full_messages.to_sentence
              end
            end
            redirect_to home_path
          end
        else
          discard_flash
          redirect_to link_path(resource) || home_path
        end
      }
  	end
  end

  def update
    super do |format|
      format.json { render :json => resource }
      format.js { render }
      format.all {
        unless resource.errors.blank?
          if resource.errors[:url].present?
            flash[:errors] = I18n.t("link.messages.url_blank")
          elsif resource.errors[:title].present?
            flash[:errors] = I18n.t("link.messages.title_blank")
          else
            flash[:errors] = resource.errors.full_messages.to_sentence
          end
        else
          discard_flash
        end
        redirect_to link_path(resource) || home_path
      }
    end
  end


  private

  def allowed_params
    [:url, :image, :callback, :width, :height, :callback_url, :loaded, :language, :license_id, :age_min, :age_max, :scope, :avatar, :is_embed, :tag_list=>[]]
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
