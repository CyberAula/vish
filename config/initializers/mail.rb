# Turn off auto TLS for e-mail
ActionMailer::Base.default_url_options[:host] = 'vishub.global.dit.upm.es'
ActionMailer::Base.smtp_settings[:enable_starttls_auto] = false
