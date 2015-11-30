# Set up ViSH Recommender System settings
# Store some variables in configuration to speed things up
# Config accesible in Vish::Application::config

Vish::Application.configure do
  config.after_initialize do

    rsConfig = {}
    rsConfig = config.APP_CONFIG["recommender_system"].parse_for_vish unless config.APP_CONFIG["recommender_system"].blank?

    #ViSHRS fixed settings
    config.rs_settings = {}
    config.rs_settings = rsConfig[:settings] unless rsConfig[:settings].blank?
    config.rs_settings = {:max_text_length => 20, :max_user_los => 1, :max_preselection_size => 5000}.recursive_merge(config.rs_settings)

    #Default settings to use in ViSHRS
    config.rs_default_settings = {}
    config.rs_default_settings = rsConfig[:default_settings] unless rsConfig[:default_settings].blank?
    config.rs_default_settings = {:preselection_filter_query => false, :preselection_filter_resource_type => false, :preselection_filter_languages => true, :preselection_size => 200, :preselection_size_min => 100, :only_context => true}.recursive_merge(config.rs_default_settings)

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
    config.weights = weights

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
    config.filters = filters

    #Search Engine
    config.max_matches = ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 10000
    config.rs_settings[:max_preselection_size] = [config.max_matches,config.rs_settings[:max_preselection_size]].min
    config.max_preselection_size = config.rs_settings[:max_preselection_size]

    #RS: internal settings
    config.max_user_los = config.rs_settings[:max_user_los]

    #Settings for speed up TF-IDF calculations
    config.max_text_length = config.rs_settings[:max_text_length]
    config.repository_total_entries = [ActivityObject.getAllPublicResources.count,1].max
    
    #Keep words in the configuration
    words = {}
    Word.where("occurrences > ?",5).first(5000000).each do |word|
      words[word.value] = [word.occurrences,config.repository_total_entries-1].min
    end
    config.words = words

    config.stoptags = File.read("config/stoptags.yml").split(",").map{|s| s.gsub("\n","").gsub("\"","") } rescue []
  end
end


