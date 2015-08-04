class ServicePermissionsController < ApplicationController

  before_filter :authenticate_user!
  before_filter :authenticate_user_as_admin!


  def update_permissions
  	
  end

end
