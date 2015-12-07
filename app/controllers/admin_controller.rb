class AdminController < ApplicationController
	before_filter :authenticate_user!
	before_filter :authenticate_user_as_admin!

	def index
		#pending reports
		@reports = SpamReport.where(:pending=>true).sort{|b,a| a.created_at <=> b.created_at}
		@pending = true

		@pending_reports_quantity = @reports.length
		@closed_reports_quantity = SpamReport.where(:pending=>false).length
	end

	def closed_reports
		@reports = SpamReport.where(:pending=>false).sort{|b,a| a.created_at <=> b.created_at}
		@pending = false

		@pending_reports_quantity = SpamReport.where(:pending=>true).length
		@closed_reports_quantity = @reports.length

		render :index
	end

	def users
		@users = User.registered.sort{|b,a| a.created_at <=> b.created_at}
	end

	def requests
		@requests = ServiceRequest.all
	end

	private

	def authenticate_user_as_admin!
		unless !current_user.nil? and current_user.admin?
			redirect_to home_path
		end
	end

end