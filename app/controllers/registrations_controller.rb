class RegistrationsController < Devise::RegistrationsController
  skip_before_filter :store_location

  # GET /resource/sign_up
  def new
    super
  end

  # POST /resource
  def create
    if simple_captcha_valid?

      #Infer user language from client information
      if !I18n.locale.nil? and !params[:user].nil? and I18n.available_locales.map{|i| i.to_s}.include? I18n.locale.to_s
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

end