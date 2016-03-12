class RegistrationsController < Devise::RegistrationsController
  skip_before_filter :store_location
  after_filter :process_course_enrolment, :only =>[:create]

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    if simple_captcha_valid?
      #Infer user language from client information
      if !I18n.locale.nil? and !params[:user].nil? and (params[:user][:language].blank? or !I18n.available_locales.include?(params[:user][:language].to_sym)) and I18n.available_locales.include?(I18n.locale.to_sym)
        params[:user] ||= {}
        params[:user][:language] = I18n.locale.to_s
      end

      super
    else
      build_resource
      
      #clean_up_passwords(resource)
      flash.now[:alert] = t('simple_captcha.error')   
      flash.delete :recaptcha_error
      render :new
    end
  end

  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  def update
    super
  end

  # DELETE /resource
  def destroy
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    super
  end

  private


  def process_course_enrolment
    if params[:course].present?
      course = Course.find(params[:course])
      if !course.restricted
        course.users << current_user
        CourseNotificationMailer.user_welcome_email(current_user, course)
      end
    end
  end

end