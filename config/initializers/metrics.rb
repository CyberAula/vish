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
    config.metrics_popularity[:resources] = {:w_fVisits => 0.6, :w_fLikes => 0.3, :w_fDownloads => 0.1} #Downloadable resources
    config.metrics_popularity[:non_downloadable_resources] = {:w_fVisits => 0.7, :w_fLikes => 0.3}
    config.metrics_popularity[:users] = {:w_followers => 0.4, :w_resources => 0.6}
    config.metrics_popularity[:events] = {:w_fVisits => 0.7, :w_fLikes => 0.3}
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

    #Default Ranking Metrics
    config.metrics_default_ranking = {:w_popularity => 0.7, :w_qscore => 0.3, :coefficients => {}}
    config.metrics_default_ranking = config.metrics_default_ranking.recursive_merge(metricsConfig[:default_ranking]) if metricsConfig[:default_ranking].is_a? Hash
  
    #Relevance Ranking Metric
    config.metrics_relevance_ranking = {:w_rquery => 0.8, :w_popularity => 0.1, :w_qscore => 0.1}
    config.metrics_relevance_ranking[:rquery] = {:w_title => 50, :w_description => 1, :w_tags => 40}
    config.metrics_relevance_ranking = config.metrics_relevance_ranking.recursive_merge(metricsConfig[:relevance_ranking]) if metricsConfig[:relevance_ranking].is_a? Hash
    config.metrics_relevance_ranking[:field_weights] = {
        :title => config.metrics_relevance_ranking[:rquery][:w_title],
        :description => config.metrics_relevance_ranking[:rquery][:w_description],
        :tags => config.metrics_relevance_ranking[:rquery][:w_tags],
        :name => config.metrics_relevance_ranking[:rquery][:w_title] #(For users name is used instead of title)
    }
  end
end

