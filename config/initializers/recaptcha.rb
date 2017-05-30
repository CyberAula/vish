if Vish::Application.config.enable_recaptcha
  Recaptcha.configure do |config|
    config.site_key  = Vish::Application.config.APP_CONFIG["recaptcha"]["site_key"]
    config.secret_key = Vish::Application.config.APP_CONFIG["recaptcha"]["secret_key"]
  end
end
