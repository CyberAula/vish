SettingsController.class_eval do

	def index
		redirect_to home_path if current_subject.role?("PrivateStudent")
	end

end