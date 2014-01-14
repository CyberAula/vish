# Turn off auto TLS for e-mail
ActionMailer::Base.default_url_options[:host] = 'vishub.org'
ActionMailer::Base.smtp_settings[:enable_starttls_auto] = false

if ENV['VISH_TEST']
	ActionMailer::Base.smtp_settings[:perform_deliveries] = false
end