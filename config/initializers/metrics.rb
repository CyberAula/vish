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
  end
end