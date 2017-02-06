# Set up ViSH Recommender System settings
# Store some variables in configuration to speed things up
# Config accesible in Vish::Application::config

Vish::Application.configure do
  config.after_initialize do

    #(RS settings are stored directly in config to enhance performance)

    rsConfig = {}
    rsConfig = config.APP_CONFIG["recommender_system"].parse_for_vish unless config.APP_CONFIG["recommender_system"].blank?

    #ViSHRS fixed settings
    config.rs_settings = {}
    config.rs_settings = rsConfig[:settings] unless rsConfig[:settings].blank?
    config.rs_settings = {:max_text_length => 20, :max_user_los => 1, :max_user_pastlos => 1, :max_preselection_size => 5000}.recursive_merge(config.rs_settings)
    config.rs_settings[:max_preselection_size] = [config.max_matches,config.rs_settings[:max_preselection_size]].min

    #Default settings to use in ViSHRS
    config.rs_default_settings = {}
    config.rs_default_settings = rsConfig[:default_settings] unless rsConfig[:default_settings].blank?
    config.rs_default_settings = {:preselection_filter_query => false, :preselection_filter_resource_type => false, :preselection_filter_languages => true, :preselection_filter_own_resources => true, :preselection_authored_resources => true, :preselection_size => 200, :preselection_size_min => 100, :only_context => true}.recursive_merge(config.rs_default_settings)

    #Default weights
    weights = {}
    weights[:default_rs] = RecommenderSystem.defaultRSWeights
    weights[:default_los] = RecommenderSystem.defaultLoSWeights
    weights[:default_us] = RecommenderSystem.defaultUSWeights
    if rsConfig[:weights]
      weights[:default_rs] = weights[:default_rs].recursive_merge(rsConfig[:weights][:default_rs]) if rsConfig[:weights][:default_rs]
      weights[:default_los] = weights[:default_los].recursive_merge(rsConfig[:weights][:default_los]) if rsConfig[:weights][:default_los]
      weights[:default_us] = weights[:default_us].recursive_merge(rsConfig[:weights][:default_us]) if rsConfig[:weights][:default_us]
      weights[:popularity] = weights[:popularity].recursive_merge(rsConfig[:weights][:popularity]) if rsConfig[:weights][:popularity]
    end
    config.rs_weights = weights

    #Default filters
    filters = {}
    filters[:default_rs] = RecommenderSystem.defaultRSFilters
    filters[:default_los] = RecommenderSystem.defaultLoSFilters
    filters[:default_us] = RecommenderSystem.defaultUSFilters
    if rsConfig[:filters]
      filters[:default_rs] = filters[:default_rs].recursive_merge(rsConfig[:filters][:default_rs])if rsConfig[:filters][:default_rs]
      filters[:default_los] = filters[:default_los].recursive_merge(rsConfig[:filters][:default_los])if rsConfig[:filters][:default_los]
      filters[:default_us] = filters[:default_us].recursive_merge(rsConfig[:filters][:default_us])if rsConfig[:filters][:default_us]
    end
    config.rs_filters = filters

    #RS: internal settings
    config.rs_max_preselection_size = config.rs_settings[:max_preselection_size]
    config.rs_max_user_los = config.rs_settings[:max_user_los]
    config.rs_max_user_pastlos = config.rs_settings[:max_user_pastlos]

    #Settings for speed up TF-IDF calculations
    config.rs_max_text_length = config.rs_settings[:max_text_length]
    if ActiveRecord::Base.connection.table_exists?('activity_objects')
      config.rs_repository_total_entries = [ActivityObject.getAllPublicResources.count,1].max
    end
    
    #Keep words in the configuration
    words = {}
    if ActiveRecord::Base.connection.table_exists?('words')
      Word.where("occurrences > ?",5).first(5000000).each do |word|
        words[word.value] = [word.occurrences,config.rs_repository_total_entries-1].min
      end
    end
    config.rs_words = words

    #RSEvaluation
    config.rs_evaluation = (!rsConfig[:evaluation].nil? and rsConfig[:evaluation][:enabled]==true)
  end
end


