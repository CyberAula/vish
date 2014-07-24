class AdminController < ApplicationController
	before_filter :authenticate_user!
	before_filter :authenticate_user_as_admin!

	def index
	end


	private

	def authenticate_user_as_admin!
		unless !current_user.nil? and current_user.admin?
			redirect_to home_path
		end
	end

end