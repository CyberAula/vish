class TeacherNotificationMailer < ActionMailer::Base
	default from: "no_reply@vishub.org"

	def notify_teacher(teacher, pupil, path) #TODO: add item link
		@teacher_name = teacher.name
		@pupil_name = pupil.name
		@path = path
		subject = t('notification.teacher.uploaded')
		mail(:to => teacher.email, 
			 :subject => subject, 
			 :content_type => "text/html").deliver
	end

	def notify_for_publish(teacher, pupil, excursion_id)
		@teacher_name = teacher.name
		@pupil_name = pupil.name
		
		mail(:to => teacher.email, 
			 :subject => subject, 
			 :content_type => "text/html").deliver
	end
end
