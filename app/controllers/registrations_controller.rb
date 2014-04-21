class RegistrationsController < Devise::RegistrationsController
    
    def create
      if simple_captcha_valid?
        super
      else
        build_resource
        #clean_up_passwords(resource)
        flash.now[:alert] = t('simple_captcha.error')   
        flash.delete :recaptcha_error
        render :new
      end
    end
  end