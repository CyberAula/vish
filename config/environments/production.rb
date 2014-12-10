Vish::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  if Vish::Application.config.APP_CONFIG["test_domain"]
    config.assets.compress = false
  else
    config.assets.compress = true
  end

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( vish_editor.css )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  if !Vish::Application.config.APP_CONFIG["mail"].nil?
    # ActionMailer Config
    # Setup for production - deliveries, no errors raised
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.default :charset => "utf-8"
    delivery_method_sym = Vish::Application.config.APP_CONFIG["mail"]["type"].downcase.to_sym

    config.action_mailer.delivery_method = delivery_method_sym

    if delivery_method_sym == :smtp
      config.action_mailer.smtp_settings = {
        :address   => Vish::Application.config.APP_CONFIG["mail"]["credentials"]["address"],
        :port      => Vish::Application.config.APP_CONFIG["mail"]["credentials"]["port"],
        :user_name => Vish::Application.config.APP_CONFIG["mail"]["credentials"]["username"],
        :password  => Vish::Application.config.APP_CONFIG["mail"]["credentials"]["password"],
        :domain => Vish::Application.config.APP_CONFIG["mail"]["credentials"]["domain"],
        :authentication => Vish::Application.config.APP_CONFIG["mail"]["credentials"]["authentication"].to_sym,
        :enable_starttls_auto => Vish::Application.config.APP_CONFIG["mail"]["credentials"]["enable_starttls_auto"]
      }
    end
  end

  #default host for routes
  Rails.application.routes.default_url_options[:host] = config.APP_CONFIG['domain']
end
