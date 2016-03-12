require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Vish
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.  
    config.APP_CONFIG = YAML.load_file("config/application_config.yml")[ENV["RAILS_ENV"] || "development"]
    
    config.name = (config.APP_CONFIG['name'].nil? ? "ViSH" : config.APP_CONFIG['name'])

    config.full_domain = "http://" + config.APP_CONFIG['domain']
    config.full_code_domain = "http://" + (config.APP_CONFIG['code_domain'] || config.APP_CONFIG['domain'])

    # Login and register policies
    #Default values
    config.register_policy = "HYBRID"
    config.login_policy = "LOCAL"
    #Custom values
    config.register_policy = config.APP_CONFIG["register_policy"] if ["REGISTER_ONLY","INVITATION_ONLY","HYBRID"].include? config.APP_CONFIG["register_policy"]
    config.login_policy = config.APP_CONFIG["login_policy"] if ["LOCAL","CAS"].include? config.APP_CONFIG["login_policy"]
    #Features related to login and register policies
    config.cas = config.login_policy==="CAS" and !config.APP_CONFIG["CAS"].blank?
    config.registrations = ["REGISTER_ONLY","HYBRID"].include? config.register_policy
    config.invitations = ["INVITATION_ONLY","HYBRID"].include? config.register_policy

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    # config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true
    
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = false

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    
    config.after_initialize do
      I18n.available_locales = [:en, :es, :de, :nl, :hu, :fr]
      unless config.APP_CONFIG['languages'].nil?
        I18n.available_locales = (config.APP_CONFIG['languages'].map{|l| l.to_sym} & I18n.available_locales)
      end
      
      ActsAsTaggableOn.strict_case_match = true

      config.available_thumbnail_styles = SocialStream::Documents.picture_styles.keys.map{|k| k.to_s}
    end

    #action  mailer default content_type
    ActionMailer::Base.default :content_type => "text/html"

    #Load ViSH Editor plugin
    config.before_configuration do
      $:.unshift File.expand_path("#{__FILE__}/../../lib/plugins/vish_editor/lib")
      require 'vish_editor'
    end

    #Require core extensions
    Dir[File.join(Rails.root, "lib", "core_ext", "*.rb")].each {|l| require l }

    config.after_initialize do
      #Agnostic random
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        config.agnostic_random = "RANDOM()"
      else
        #MySQL
        config.agnostic_random = "RAND()"
      end
    end

    #Tracker
    config.trackingSystem = (!config.APP_CONFIG['trackingSystemAPIKEY'].nil? and !config.APP_CONFIG['trackingSystemAPIURL'].nil?)

    #External services settings
    config.uservoice = (!config.APP_CONFIG['uservoice'].nil? and !config.APP_CONFIG['uservoice']["scriptURL"].nil?)
    config.ganalytics = (!config.APP_CONFIG['ganalytics'].nil? and !config.APP_CONFIG['ganalytics']["trackingID"].nil?)
    config.gwebmastertools = (!config.APP_CONFIG['gwebmastertools'].nil? and !config.APP_CONFIG['gwebmastertools']["site-verification"].nil?)
    config.facebook = (!config.APP_CONFIG['facebook'].nil? and !config.APP_CONFIG['facebook']["appID"].nil? and !config.APP_CONFIG['facebook']["accountID"].nil?)
    config.twitter = (!config.APP_CONFIG['twitter'].nil? and config.APP_CONFIG['twitter']["enable"]===true)
    config.gplus = (!config.APP_CONFIG['gplus'].nil? and config.APP_CONFIG['gplus']["enable"]===true)

    #Tags settings
    if config.APP_CONFIG['tagsSettings'].blank?
      config.tagsSettings = {}
    else
      config.tagsSettings = config.APP_CONFIG['tagsSettings']
    end

    if config.tagsSettings["maxLength"].blank?
      config.tagsSettings["maxLength"] = 20
    end

    if config.tagsSettings["maxTags"].blank?
      config.tagsSettings["maxTags"] = 8
    end

    if config.tagsSettings["triggerKeys"].blank?
      config.tagsSettings["triggerKeys"] = ['enter', 'comma', 'tab', 'space']
    end

    #Catalogue
    if config.APP_CONFIG['catalogue'].blank?
      config.catalogue = {} 
    else
      config.catalogue = config.APP_CONFIG['catalogue']
    end
    config.catalogue['mode'] = "matchany" if config.catalogue['mode'].blank?
    config.catalogue["qualityThreshold"] = nil unless config.catalogue["qualityThreshold"].is_a? Numeric
  end
end
