# Turn off auto TLS for e-mail
ActionMailer::Base.default_url_options[:host] = Vish::Application.config.APP_CONFIG['domain']
ActionMailer::Base.smtp_settings[:enable_starttls_auto] = false

if Vish::Application.config.APP_CONFIG["test_domain"]
	ActionMailer::Base.smtp_settings[:perform_deliveries] = false
end