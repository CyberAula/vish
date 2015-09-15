class TeacherNotificationMailer < ActionMailer::Base
	def notify_teacher(teacher, subject, notification, object_id)
		@teacher = teacher
		@subject = subject
		@notification = notification
		@object_id = object_id
		mail(:to => teacher.mail, :subject => subject)
	end
end
