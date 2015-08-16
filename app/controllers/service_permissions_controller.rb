class ServicePermissionsController < ApplicationController

  before_filter :authenticate_user!


  def update_permissions  	
  	authorize! :manage, ServicePermission

  	#first destroy all old entries
  	ServicePermission.destroy_all(:owner_id => params["owner_id"])
  	if params["sp"]
	  	params["sp"].each do |sp|
	  		s = ServicePermission.new
		    s.owner_id = params["owner_id"]
		    s.key = sp
		    s.save
	  	end
  	end
  	
  	redirect_to url_for(User.find_by_actor_id(params["owner_id"]))
  end


end
