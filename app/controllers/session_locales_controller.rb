class SessionLocalesController < ActionController::Base
  
  def create
    new_locale = params[:new_locale].to_sym
    if I18n.available_locales.include?(new_locale)
      #Add locale to the session
      session[:locale] =  new_locale 
    
      #Add locale to the user profile
      if user_signed_in?
        current_subject.update_attribute(:language, params[:new_locale])
      end

      flash[:success] = t('lang.changed', :lang => t(:language_name, :locale => params[:new_locale]), locale: new_locale)

    else

      flash[:error] = t('lang.error', :lang => params[:new_locale])
      
    end
  
    redirect_to request.referer
  end
  
end
