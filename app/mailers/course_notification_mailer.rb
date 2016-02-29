class CourseNotificationMailer < ActionMailer::Base
	default from: Vish::Application.config.APP_CONFIG["no_reply_mail"]


	def user_welcome_email(user, course)
		@user = user
		@course = course
		subject = t('course.first_mail.subject')

		mail(:to => user.email, 
			 :subject => subject, 
			 :content_type => "text/html").deliver
	end
end
