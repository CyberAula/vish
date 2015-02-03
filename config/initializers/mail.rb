vish_mail_settings = Vish::Application.config.APP_CONFIG["mail"]

ActionMailer::Base.default_url_options[:host] = Vish::Application.config.APP_CONFIG['domain']

if Vish::Application.config.APP_CONFIG["test_domain"]
	ActionMailer::Base.perform_deliveries = false
else
	ActionMailer::Base.perform_deliveries = true
end

ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.default :charset => "utf-8"

#Default options
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings[:enable_starttls_auto] = false

unless vish_mail_settings.nil?
	#Set delivery method (SMTP, Sendmail, ...)
	unless vish_mail_settings["type"].nil?
		ActionMailer::Base.delivery_method = Vish::Application.config.APP_CONFIG["mail"]["type"].downcase.to_sym
	end

	if ActionMailer::Base.delivery_method == :smtp
		#Fill ActionMailer::Base.smtp_settings
		vish_smtp_settings = {}
		vish_smtp_settings[:address] = vish_mail_settings["address"] unless vish_mail_settings["address"].blank?
		vish_smtp_settings[:port] = vish_mail_settings["port"] unless vish_mail_settings["port"].blank?
		vish_smtp_settings[:authentication] = vish_mail_settings["authentication"] unless vish_mail_settings["authentication"].blank?
		unless vish_mail_settings["credentials"].nil?
			vish_smtp_settings[:user_name] = vish_mail_settings["credentials"]["username"] unless vish_mail_settings["credentials"]["username"].blank?
			vish_smtp_settings[:password] = vish_mail_settings["credentials"]["password"] unless vish_mail_settings["credentials"]["password"].blank?
		end
		vish_smtp_settings[:domain] = vish_mail_settings["domain"] unless vish_mail_settings["domain"].blank?
		if vish_mail_settings["enable_starttls_auto"].blank?
			vish_smtp_settings[:enable_starttls_auto] = false
		else
			vish_smtp_settings[:enable_starttls_auto] = vish_mail_settings["enable_starttls_auto"] unless vish_mail_settings["enable_starttls_auto"].blank?
		end

		ActionMailer::Base.smtp_settings = vish_smtp_settings

	elsif ActionMailer::Base.delivery_method == :sendmail
		#Fill ActionMailer::Base.sendmail_settings
		vish_sendmail_settings = {}
		vish_sendmail_settings[:location] = vish_mail_settings["location"] unless vish_mail_settings["location"].blank?
		vish_sendmail_settings[:arguments] = vish_mail_settings["arguments"] unless vish_mail_settings["arguments"].blank?
		ActionMailer::Base.sendmail_settings = vish_sendmail_settings
	else
		#:file, :test, ...
	end
end

