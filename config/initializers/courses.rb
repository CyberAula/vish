#detect if we have courses, we need courses in models available in application_config.yml 
#and we need moodle_url in application_config.yml 
#and at least one created course (this param will be updated when a course is created)
Vish::Application.configure do
  config.after_initialize do

		config.courses_count  = 0
		config.courses_enabled = false

		if ActiveRecord::Base.connection.table_exists?('courses')
			config.courses_count = Course.count
			if Vish::Application.config.APP_CONFIG["moodle_url"].present? && (VishConfig.getAllAvailableModels.include? "Course")
				config.courses_enabled = true
			end
		end

  end
end