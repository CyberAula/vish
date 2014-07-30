class RegistrationsController < Devise::RegistrationsController
    
    def create
      if simple_captcha_valid?

        #Infer user language from client information
        if !I18n.locale.nil? and !params[:user].nil? and Vish::Application.config.platformLanCodes.include? I18n.locale.to_s
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
  end