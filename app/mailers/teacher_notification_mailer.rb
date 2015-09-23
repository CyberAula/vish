class TeacherNotificationMailer < ActionMailer::Base
	default from: "no_reply@vishub.org"

	def notify_teacher(teacher, pupil, path) #TODO: add item link
		@teacher_name = teacher.name
		@pupil_name = pupil.name
		@path = path
		@classroom = pupil.private_student_group

		subject = t('notification.teacher.uploaded')
		mail(:to => teacher.email, 
			 :subject => subject, 
			 :content_type => "text/html").deliver
	end

	def notify_for_publish(teacher, pupil, excursion, classroom)
		@teacher_name = teacher.name
		@pupil_name = pupil.name
		@excursion = excursion
		@classroom = classroom

		subject = t('notification.teacher.published')


		mail(:to => teacher.email, 
			 :subject => subject, 
			 :content_type => "text/html").deliver
	end
end
