# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

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
