# encoding: utf-8

###############
# ViSH Recommender System (and Search Engine)
###############

class RecommenderSystem

  def self.resource_suggestions(options={})
    # Step 0: Initialize all variables
    options = prepareOptions(options)

    #Step 1: Preselection
    preSelectionLOs = getPreselection(options)

    #Step 2: Scoring
    rankedLOs = calculateScore(preSelectionLOs,options)

    #Step 3: Filtering
    filteredLOs = filter(rankedLOs,options)

    #Step 4: Sorting
    sortedLOs = filteredLOs.sort { |a,b|  b.score <=> a.score }

    #Step 5: Delivering
    return sortedLOs.first(options[:n])
  end

  # Step 0: Initialize all variables
  def self.prepareOptions(options)
    options = {:n => 20, :settings => Vish::Application::config.default_settings}.recursive_merge(options)
    unless options[:user].blank?
      options[:user_los] = [] #TODO. Get and limit LOs from user
      options[:user_los] = options[:user_los].first(options[:max_user_los] || Vish::Application::config.max_user_los)
    end
    options
  end

  #Step 1: Preselection
  def self.getPreselection(options)
    # Get resources using the Search Engine
    searchOpts = {}
    searchOpts[:n] = [options[:settings][:preselection_size],Vish::Application::config.settings[:max_preselection_size]].min
    searchOpts[:order] = "random"

    # Define some filters for the preselection

    # A. Query.
    unless options[:settings][:preselection_filter_keywords] == false
      keywords = compose_keywords(options)
      searchOpts[:keywords] = keywords unless keywords.blank?
    end

    # B. Resource type.
    unless options[:settings][:preselection_filter_resource_type] == false
      options[:models] = [options[:lo].class] if options[:lo]
    end
    options[:models] = VishConfig.getAvailableResourceModels({:return_instances => true}) if options[:models].blank?
    options[:model_names] = options[:models].map{|m| m.name}
    searchOpts[:models] = options[:models] #Only search for desired models
    
    # C. Language.
    unless options[:settings][:preselection_filter_languages] == false
      # Multilanguage approach.
      preselectionLanguages = []
      preselectionLanguages << options[:lo].language if options[:lo]
      if options[:user]
        preselectionLanguages << options[:user].language
        preselectionLanguages += options[:user_los].map{|lo| lo.language} if options[:user_los]
      end
      preselectionLanguages.compact.uniq!
      preselectionLanguages = preselectionLanguages & VishConfig.getAllDefinedLanguages
      searchOpts[:language] = preselectionLanguages unless preselectionLanguages.blank?
    end

    # D. Repeated resources.
    searchOpts[:subjects_to_avoid] = [options[:user]] if options[:user]
    searchOpts[:ao_ids_to_avoid] = [options[:lo].activity_object.id] if options[:lo]

    #Call search engine
    preSelection = (Search.search(searchOpts)) rescue []

    #Add other resources of the same author
    unless options[:lo].nil? or options[:lo].author.nil? or (options[:user] and Actor.normalize_id(options[:user]) == options[:lo].author.id)
      authorResources = ActivityObject.limit(50).order(Vish::Application::config.agnostic_random).authored_by(options[:lo].author).where("scope=0 and object_type IN (?) and activity_objects.id not IN (?)",options[:model_names],options[:lo].activity_object.id)
      preSelection += authorResources.map{|ao| ao.object}
      preSelection.uniq!
    end
    preSelection.compact!
    
    pSL = preSelection.length
    if pSL < options[:n]
      unless searchOpts[:language].blank? and searchOpts[:keywords].blank?
        #Fill it with random resources (no filters)
        searchOptionsRandom = searchOpts
        searchOptionsRandom[:n] = (searchOpts[:n]-pSL)
        searchOptionsRandom[:ao_ids_to_avoid] = preSelection.map{|lo| lo.activity_object.id}
        searchOptionsRandom[:ao_ids_to_avoid] << options[:lo].activity_object.id if options[:lo]
        searchOptionsRandom.delete(:keywords)
        searchOptionsRandom.delete(:language)
        preSelection += Search.search(searchOptionsRandom).compact rescue []
      end
    end

    return preSelection
  end

  #Step 2: Scoring
  def self.calculateScore(preSelectionLOs,options)
    return preSelectionLOs if preSelectionLOs.blank?

    weights = RecommenderSystem.getRSWeights(options)
    weights_sum = 1
    options[:weights_los] = RecommenderSystem.getLoSWeights(options)
    options[:weights_us] = RecommenderSystem.getUSWeights(options)

    filters = RecommenderSystem.getRSFilters(options)

    if options[:lo].blank?
      weights_sum = (weights_sum-weights[:los_score])
      weights[:los_score] = 0
      filters[:los_score] = 0
      options[:filtering_los] = false
    end
    if options[:user].blank?
      weights_sum = (weights_sum-weights[:us_score])
      weights[:us_score] = 0
      filters[:us_score] = 0
      options[:filtering_us] = false
    end
    
    weights.each{ |k, v| weights[k] = [1,v/weights_sum.to_f].min } if (weights_sum < 1 and weights_sum > 0)

    #Check if any individual filtering should be performed
    if options[:filtering_los].nil?
      options[:filters_los] = RecommenderSystem.getLoSFilters(options)
      options[:filtering_los] = options[:filters_los].map {|k,v| v}.sum > 0
    end
    if options[:filtering_us].nil?
      options[:filters_us] = RecommenderSystem.getUSFilters(options)
      options[:filtering_us] = options[:filters_us].map {|k,v| v}.sum > 0
    end

    calculateLoSimilarityScore = ((weights[:los_score]>0)||(filters[:los_score]>0)||options[:filtering_los])
    calculateUserSimilarityScore = ((weights[:us_score]>0)||(filters[:us_score]>0)||options[:filtering_us] )
    calculateQualityScore = ((weights[:quality_score]>0)||(filters[:quality_score]>0))
    calculatePopularityScore = ((weights[:popularity_score]>0)||(filters[:popularity_score]>0))

    preSelectionLOs.map{ |lo|
      los_score = calculateLoSimilarityScore ? RecommenderSystem.loSimilarityScore(options[:lo],lo,options) : 0
      (lo.filtered=true and next) if (calculateLoSimilarityScore and los_score < filters[:los_score])
      
      us_score = calculateUserSimilarityScore ? RecommenderSystem.userSimilarityScore(options[:user],lo,options) : 0
      (lo.filtered=true and next) if (calculateUserSimilarityScore and us_score < filters[:us_score])
      
      quality_score = calculateQualityScore ? RecommenderSystem.qualityScore(lo) : 0
      (lo.filtered=true and next) if (calculateQualityScore and quality_score < filters[:quality_score])
      
      popularity_score = calculatePopularityScore ? RecommenderSystem.popularityScore(lo) : 0
      (lo.filtered=true and next) if (calculatePopularityScore and popularity_score < filters[:popularity_score])

      lo.score = weights[:los_score] * los_score + weights[:us_score] * us_score + weights[:quality_score] * quality_score + weights[:popularity_score] * popularity_score
    }

    preSelectionLOs
  end

  #Step 3: Filtering
  #Filtered Learning Objects are marked with the lo.filtered field.
  def self.filter(rankedLOs,options)
    rankedLOs.select{|lo| lo.filtered.nil? }
  end

  #Learning Object Similarity Score, [0,1] scale
  def self.loSimilarityScore(loA,loB,options={})
    weights = options[:weights_los] || RecommenderSystem.getLoSWeights(options)
    filters = options[:filtering_los]!=false ? (options[:filters_los] || RecommenderSystem.getLoSFilters(options)) : nil
    
    titleS = RecommenderSystem.getSemanticDistance(loA.title,loB.title)
    descriptionS = RecommenderSystem.getSemanticDistance(loA.description,loB.description)
    languageS = RecommenderSystem.getSemanticDistanceForLanguage(loA.language,loB.language)
    keywordsS = RecommenderSystem.getTextArraySemanticDistance(loA.tag_list,loB.tag_list)

    return -1 if (!filters.blank? and (titleS < filters[:title] || descriptionS < filters[:description] || languageS < filters[:language] || yearS < filters[:keywords]))

    return weights[:title] * titleS + weights[:description] * descriptionS + weights[:language] * languageS + weights[:keywords] * keywordsS
  end

  #User profile Similarity Score, [0,1] scale
  def self.userSimilarityScore(user,lo,options={})
    weights = options[:weights_us] || RecommenderSystem.getUSWeights(options)
    filters = options[:filtering_us]!=false ? (options[:filters_us] || RecommenderSystem.getUSFilters(options)) : nil
    
    languageS = RecommenderSystem.getSemanticDistanceForLanguage(user.language,lo.language)
    keywordsS = RecommenderSystem.getTextArraySemanticDistance(user.tag_list,lo.tag_list)

    losS = 0
    unless options[:user_los].blank?
      options[:user_los].each do |pastLo|
        losS += RecommenderSystem.loProfileSimilarityScore(pastLo,lo,options.merge({:filtering_los => false}))
      end
      losS = losS/options[:user_los].length
    end

    return -1 if (!filters.blank? and (languageS < filters[:language] || keywordsS < filters[:keywords] || losS < filters[:los]))

    return weights[:language] * languageS + weights[:keywords] * keywordsS + weights[:los] * losS
  end

  #Popularity Score (between 0 and 1)
  #See scheduled:recalculatePopularity task in lib/tasks/scheduled.rake to see the popularity metric
  def self.popularityScore(lo)
    return [[lo.popularity/1000000.to_f,0].max,1].min
  end

  #Quality Score (between 0 and 1)
  #See app/decorators/social_stream/base/activity_object_decorator.rb, method calculate_qscore, to see the quality metric
  def self.qualityScore(lo)
    return [[lo.qscore/1000000.to_f,0].max,1].min
  end


  private

  #######################
  ## Utils
  #######################

  def self.compose_keywords(options)
    keywords = []
    #Subject tags (i.e. user tags)
    keywords += options[:user].tag_list unless options[:user].nil?
    #Resource tags
    keywords += options[:lo].tag_list unless options[:lo].nil?
    #Keywords specified in the options
    keywords += options[:keywords] if options[:keywords].is_a? Array
    keywords.uniq
  end

  #######################
  ## General Utils for the Recommender System
  #######################

  #Semantic distance in a [0,1] scale. 
  #It calculates the semantic distance using the Cosine similarity measure, and the TF-IDF function to calculate the vectors.
  def self.getSemanticDistance(textA,textB)
    return 0 unless (textA.is_a? String or textB.is_a? String)
    return 0 if (textA.blank? or textB.blank?)

    #We need to limit the length of the text due to performance issues
    textA = textA.first(Vish::Application::config.max_text_length)
    textB = textB.first(Vish::Application::config.max_text_length)

    numerator = 0
    denominator = 0
    denominatorA = 0
    denominatorB = 0

    wordsTextA = RecommenderSystem.processFreeText(textA)
    wordsTextB = RecommenderSystem.processFreeText(textB)

    # Get the text with more/less words.
    # words = [wordsTextA.keys, wordsTextB.keys].sort_by{|words| -words.length}.first

    #All words
    words = (wordsTextA.keys + wordsTextB.keys).uniq

    words.each do |word|
      #We could use here TFIDF as well. But we are going to use just the number of occurrences.
      occurrencesTextA = wordsTextA[word] || 0
      occurrencesTextB = wordsTextB[word] || 0
      wordIDF = RecommenderSystem.IDF(word)
      tfidf1 = RecommenderSystem.TFIDF(word,textA,{:occurrences => occurrencesTextA, :idf => wordIDF})
      tfidf2 = RecommenderSystem.TFIDF(word,textB,{:occurrences => occurrencesTextB, :idf => wordIDF})
      numerator += (tfidf1 * tfidf2)
      denominatorA += tfidf1**2
      denominatorB += tfidf2**2
    end

    denominator = Math.sqrt(denominatorA) * Math.sqrt(denominatorB)
    return 0 if denominator==0

    numerator/denominator
  end

  def self.processFreeText(text)
    return {} unless text.is_a? String
    text = text.gsub(/([\n])/," ")
    text =  I18n.transliterate(text.downcase.strip)
    words = Hash.new
    text.split(" ").each do |word|
      words[word] = 0 if words[word].nil?
      words[word] += 1
    end
    words
  end

  # Term Frequency (TF)
  def self.TF(word,text,options={})
    return options[:occurrences] if options[:occurrences].is_a? Numeric
    RecommenderSystem.processFreeText(text)[word] || 0
  end

  # Inverse Document Frequency (IDF)
  def self.IDF(word,options={})
    return options[:idf] if options[:idf].is_a? Numeric

    allResourcesInRepository = Vish::Application::config.repository_total_entries
    # occurrencesOfWordInRepository = (Word.find_by_value(word).occurrences rescue 1) #Too slow for real time recommendations
    occurrencesOfWordInRepository = Vish::Application::config.words[word] || 1

    allResourcesInRepository = [allResourcesInRepository,1].max
    occurrencesOfWordInRepository = [[occurrencesOfWordInRepository,1].max,allResourcesInRepository].min

    # Math::log10 for use base 10
    Math.log(allResourcesInRepository/occurrencesOfWordInRepository.to_f) rescue 1
  end

  # TF-IDF
  def self.TFIDF(word,text,options={})
    tf = RecommenderSystem.TF(word,text,options)
    return 0 if tf==0

    idf = RecommenderSystem.IDF(word,options)
    return 0 if idf==0

    return (tf * idf)
  end

  #Semantic distance between keyword arrays (in a 0-1 scale)
  def self.getTextArraySemanticDistance(textArrayA,textArrayB)
    return 0 if textArrayA.blank? or textArrayB.blank?
    return 0 unless textArrayA.is_a? Array and textArrayB.is_a? Array

    return getSemanticDistance(textArrayA.join(" "),textArrayB.join(" "))
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for categorical fields.
  #Return 1 if both fields are equal, 0 if not.
  def self.getSemanticDistanceForCategoricalFields(stringA,stringB)
    stringA = RecommenderSystem.processFreeText(stringA).first[0] rescue nil
    stringB = RecommenderSystem.processFreeText(stringB).first[0] rescue nil
    return 0 if stringA.blank? or stringB.blank?
    return 1 if stringA === stringB
    return 0
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for numeric values.
  def self.getSemanticDistanceForNumericFields(numberA,numberB,scale=[0,100])
    return 0 unless numberA.is_a? Numeric and numberB.is_a? Numeric
    numberA = [[numberA,scale[0]].max,scale[1]].min
    numberB = [[numberB,scale[0]].max,scale[1]].min
    (1-((numberA-numberB).abs)/(scale[1]-scale[0]).to_f) ** 2
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for categorical fields.
  #Return 1 if both fields are equal, 0 if not.
  def self.getSemanticDistanceForLanguage(stringA,stringB)
    return 0 if ["independent","ot"].include? stringA
    return getSemanticDistanceForCategoricalFields(stringA,stringB)
  end

  ############
  # Get user settings
  ############

  def self.getRSWeights(options={})
    getRSUserSetting("rs","weights",options)
  end

  def self.getLoSWeights(options={})
    getRSUserSetting("los","weights",options)
  end

  def self.getUSWeights(options={})
    getRSUserSetting("us","weights",options)
  end

  def self.getRSFilters(options={})
    getRSUserSetting("rs","filters",options)
  end

  def self.getLoSFilters(options={})
    getRSUserSetting("los","filters",options)
  end

  def self.getUSFilters(options={})
    getRSUserSetting("us","filters",options)
  end

  def self.getRSUserSetting(settingName,settingFamily,options={})
    settingKey = (settingName + "_" + settingFamily).to_sym #e.g. :rs_weights

    userSettings = options[:user_settings][settingKey] if options[:user_settings]
    if userSettings.blank?
      defaultKey = ("default_" + settingName).to_sym #e.g. :default_rs
      vishRSConfig = (settingFamily=="weights") ? Vish::Application::config.weights : Vish::Application::config.filters
      userSettings = vishRSConfig[defaultKey]
    end

    userSettings
  end


  # Default weights for the Recommender System provided by ViSH
  # These weights can be overriden in the application_config.yml file.
  # The current default weights can be accesed in the Vish::Application::config.weights variable.
  def self.defaultRSWeights
    {
      :los_score => 0.4,
      :us_score => 0.4,
      :quality_score => 0.10,
      :popularity_score => 0.10
    }
  end

  def self.defaultLoSWeights
    {
      :title => 0.2,
      :description => 0.15,
      :language => 0.5,
      :keywords => 0.15
    }
  end

  def self.defaultUSWeights
    {
      :language => 0.25,
      :keywords => 0.25,
      :los => 0.5
    }
  end

  def self.defaultPopularityWeights
    {
      :visit_count => 0.4,
      :like_count => 0.3,
      :download_count => 0.3
    }
  end

  # Default filters for the Recommender System provided by ViSH
  # These filters can be overriden in the application_config.yml file.
  # The current default filters can be accesed in the Vish::Application::config.filters variable.
  def self.defaultRSFilters
    {
      :los_score => 0,
      :us_score => 0,
      :quality_score => 0,
      :popularity_score => 0
    }
  end

  def self.defaultLoSFilters
    {
      :title => 0,
      :description => 0,
      :language => 0,
      :keywords => 0
    }
  end

  def self.defaultUSFilters
    {
      :language => 0,
      :keywords => 0,
      :los => 0
    }
  end

end