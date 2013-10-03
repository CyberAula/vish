class SpamReportMailer < ActionMailer::Base
  default :from => Vish::Application.config.spam_report_from

  def send_report(user, report_value, issue, activity_object_id)
    @user = user
    @report_value = report_value
    @issue = issue
    @activity_object_id = activity_object_id
    mail(:to => Vish::Application.config.spam_report_recipient, :subject => "ViSH spam/error report")
  end


end
