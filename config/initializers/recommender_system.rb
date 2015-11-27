# Set up ViSH Recommender System settings
# Store some variables in configuration to speed things up
# Config accesible in Vish::Application::config

Vish::Application.configure do
  config.after_initialize do
    #ViSHRS fixed settings
    config.settings = {:max_text_length => 20, :max_user_los => 2, :max_preselection_size => 5000}

    #Default settings to use in ViSHRS
    config.default_settings = {:preselection_filter_query => false, :preselection_filter_resource_type => false, :preselection_filter_languages => true, :preselection_size => 500}

    #Default weights
    weights = {}
    weights[:default_rs] = RecommenderSystem.defaultRSWeights
    weights[:default_los] = RecommenderSystem.defaultLoSWeights
    weights[:default_us] = RecommenderSystem.defaultUSWeights
    config.weights = weights

    #Default filters
    filters = {}
    filters[:default_rs] = RecommenderSystem.defaultRSFilters
    filters[:default_los] = RecommenderSystem.defaultLoSFilters
    filters[:default_us] = RecommenderSystem.defaultUSFilters
    config.filters = filters

    #Search Engine
    config.max_matches = ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 10000
    config.settings[:max_preselection_size] = [config.max_matches,config.settings[:max_preselection_size]].min

    #RS: internal settings
    config.max_user_los = (config.settings[:max_user_los].is_a?(Numeric) ? config.settings[:max_user_los] : 2)

    #Settings for speed up TF-IDF calculations
    config.max_text_length = (config.settings[:max_text_length].is_a?(Numeric) ? config.settings[:max_text_length] : 20)
    config.repository_total_entries = ActivityObject.getAllPublicResources.count
    
    #Keep words in the configuration
    words = {}
    Word.where("occurrences > ?",1).first(5000000).each do |word|
      words[word.value] = word.occurrences
    end
    config.words = words

    #Stop words (readed from the file stopwords.yml)
    config.stopwords = File.read("config/stopwords.yml").split(",").map{|s| s.gsub("\n","").gsub("\"","") } rescue []
  end
end


