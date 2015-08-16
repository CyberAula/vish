module AdminHelper 

	def admin_path
		"/admin"
	end

	def admin_open_reports_path
		admin_path
	end

	def admin_closed_reports_path
		admin_path + "/closed_reports"
	end

	def admin_users_path
		admin_path+ "/users"
	end

	def open_spam_report(report)
		"/spam_reports/"+report.id.to_s+"/open"
	end

	def close_spam_report(report)
		"/spam_reports/"+report.id.to_s+"/close"
	end

	def change_role_user_path(subject)
		user_path(subject) + "/edit_role"
	end

	def update_role_user_path(subject)
		user_path(subject) + "/update_role"
	end

	def admin_requests_path
		admin_path+ "/requests"
	end

end