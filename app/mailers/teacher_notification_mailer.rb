class TeacherNotificationMailer < ActionMailer::Base
	default from: 'no-reply@example.com'

	def notify_teacher(teacher, pupil)
		@teacher_name = teacher.name
		@pupil_name = pupil.name
		mail(:to => "", 
			 :subject => "Han subido una excursión", 
			 :content_type => "text/html").deliver
	end

	def notify_for_publish(teacher, pupil)

	end
end
