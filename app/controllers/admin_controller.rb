class AdminController < ApplicationController
	before_filter :authenticate_user!
	before_filter :authenticate_user_as_admin!

	def index
		#pending reports
		@reports = SpamReport.where(:pending=>true).sort{|b,a| a.created_at <=> b.created_at}
		@pending = true
	end

	def closed_reports
		@reports = SpamReport.where(:pending=>false).sort{|b,a| a.created_at <=> b.created_at}
		@pending = false
		render :index
	end

	def users
		@users = User.all.sort{|b,a| a.created_at <=> b.created_at}
	end


	private

	def authenticate_user_as_admin!
		unless !current_user.nil? and current_user.admin?
			redirect_to home_path
		end
	end

end