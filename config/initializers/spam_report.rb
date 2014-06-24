
#Configures the default from for the email sent
Vish::Application.config.spam_report_from = Vish::Application.config.APP_CONFIG["no_reply_mail"]
Vish::Application.config.spam_report_recipient = Vish::Application.config.APP_CONFIG["main_mail"]
  