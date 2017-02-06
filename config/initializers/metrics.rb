# Set up ViSH Metrics
# Store some variables in configuration to speed things up
# Config accesible in Vish::Application::config

Vish::Application.configure do
  config.after_initialize do
    #(Settings are stored directly in config to enhance performance)

    metricsConfig = {}
    metricsConfig = config.APP_CONFIG["metrics"].parse_for_vish unless config.APP_CONFIG["metrics"].blank?

    # Quality Metrics
    config.metrics_qscore = {:w_reviewers => 0.6, :w_users => 0.3, :w_teachers => 0.1}
    config.metrics_qscore = config.metrics_qscore.recursive_merge(metricsConfig[:qscore]) if metricsConfig[:qscore].is_a? Hash

    #Popularity Metrics
    config.metrics_popularity = {}
    config.metrics_popularity[:resources] = {:w_fVisits => 0.4, :w_fLikes => 0.5, :w_fDownloads => 0.1} #Downloadable resources
    config.metrics_popularity[:non_downloadable_resources] = {:w_fVisits => 0.4, :w_fLikes => 0.6}
    config.metrics_popularity[:users] = {:w_followers => 0.4, :w_resources => 0.6}
    config.metrics_popularity[:events] = {:w_fVisits => 0.5, :w_fLikes => 0.5}
    config.metrics_popularity[:coefficients] = {}
    config.metrics_popularity[:timeWindowLength] = 2 #measured in months
    unless metricsConfig[:popularity].blank?
        config.metrics_popularity[:resources] = config.metrics_popularity[:resources].recursive_merge(metricsConfig[:popularity][:resources]) if metricsConfig[:popularity][:resources].is_a? Hash
        config.metrics_popularity[:non_downloadable_resources] = config.metrics_popularity[:non_downloadable_resources].recursive_merge(metricsConfig[:popularity][:non_downloadable_resources]) if metricsConfig[:popularity][:non_downloadable_resources].is_a? Hash
        config.metrics_popularity[:users] = config.metrics_popularity[:users].recursive_merge(metricsConfig[:popularity][:users]) if metricsConfig[:popularity][:users].is_a? Hash
        config.metrics_popularity[:events] = config.metrics_popularity[:events].recursive_merge(metricsConfig[:popularity][:events]) if metricsConfig[:popularity][:events].is_a? Hash
        config.metrics_popularity[:coefficients] = config.metrics_popularity[:coefficients].recursive_merge(metricsConfig[:popularity][:coefficients]) if metricsConfig[:popularity][:coefficients].is_a? Hash
        config.metrics_popularity[:timeWindowLength] = metricsConfig[:popularity][:timeWindowLength] if metricsConfig[:popularity][:timeWindowLength].is_a? Numeric
    end
  end
end

