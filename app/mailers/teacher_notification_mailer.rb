class TeacherNotificationMailer < ActionMailer::Base
	def notify_teacher(user)
		@user = user
		mail(:to => "abenito@dit.upm.es", :subject => "Mail from student", :body => "sent mail")
	end
end
