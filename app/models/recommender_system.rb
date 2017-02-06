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
    options = {:n => 20, :settings => Vish::Application::config.rs_default_settings.recursive_merge({})}.recursive_merge(options)
    if options[:lo]
      options[:lo].tag_array_cached = options[:lo].tag_array
      options[:user] = nil if options[:settings][:only_context]
    end
    unless options[:user].blank?
      options[:user].tag_array_cached = options[:user].tag_array
      options[:user_los] = options[:user].pastLOs(options[:max_user_pastlos] || Vish::Application::config.rs_max_user_pastlos).sample(options[:max_user_los] || Vish::Application::config.rs_max_user_los) if options[:user_los].blank?
      options[:user_los].map{|pastLo| pastLo.tag_array_cached = pastLo.tag_array}
    else
      options[:user_los] = nil
    end
    options
  end

  #Step 1: Preselection
  def self.getPreselection(options)
    preSelection = []
    ao_ids_to_avoid = (options[:lo] ? [options[:lo].activity_object.id] : [-1])


    # Get random resources using the Search Engine
    searchOpts = {}
    searchOpts[:order] = "random"

    # Define some filters for the preselection

    # A. Query.
    unless options[:settings][:preselection_filter_query] == false
      keywords = compose_keywords(options)
      searchOpts[:query] = keywords unless keywords.blank?
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

    # Before search
    # Add other resources of the same author
    unless options[:settings][:preselection_authored_resources] == false
      authors = (!options[:lo].nil? ? [options[:lo].author] : (!options[:user_los].blank? ? options[:user_los].map{|pastLO| pastLO.author} : [])).compact
      unless authors.blank?
        authors = authors.reject{|a| a.id==Actor.normalize_id(options[:user])} if options[:user] and options[:settings][:preselection_filter_own_resources] != false
        unless authors.blank?
          authorResources = ActivityObject.limit(100).order(Vish::Application::config.agnostic_random).authored_by(authors).where("scope=0 and object_type IN (?) and activity_objects.id not IN (?)",options[:model_names],ao_ids_to_avoid)
          preSelection += authorResources.map{|ao|
            ao_ids_to_avoid << ao.id
            ao.object
          }.compact
          options[:settings][:preselection_size] = [options[:settings][:preselection_size]-preSelection.length,options[:settings][:preselection_size_min]].max
        end
      end
    end

    searchOpts[:n] = [options[:settings][:preselection_size],Vish::Application::config.rs_max_preselection_size].min

     # D. Repeated resources.
    searchOpts[:subjects_to_avoid] = [options[:user]] if options[:user] and options[:settings][:preselection_filter_own_resources] != false
    searchOpts[:ao_ids_to_avoid] = ao_ids_to_avoid unless ao_ids_to_avoid.blank?
    
    #Call search engine
    preSelection += (Search.search(searchOpts).compact rescue [])

    pSL = preSelection.length
    if pSL < options[:n]
      unless searchOpts[:language].blank? and searchOpts[:query].blank?
        #Fill it with random resources (no filters)
        searchOptionsRandom = searchOpts
        searchOptionsRandom[:n] = (searchOpts[:n]-pSL)
        searchOptionsRandom[:ao_ids_to_avoid] = preSelection.map{|lo| lo.activity_object.id}
        searchOptionsRandom[:ao_ids_to_avoid] << options[:lo].activity_object.id if options[:lo]
        searchOptionsRandom.delete(:query)
        searchOptionsRandom.delete(:language)
        preSelection += Search.search(searchOptionsRandom).compact rescue []
      end
    end

    return preSelection
  end

  #Step 2: Scoring
  def self.calculateScore(preSelectionLOs,options)
    return preSelectionLOs if preSelectionLOs.blank?

    weights = getRSWeights(options)
    weights_sum = 1
    options[:weights_los] = getLoSWeights(options)
    options[:weights_us] = getUSWeights(options)

    filters = getRSFilters(options)

    if options[:lo].blank?
      weights[:us_score] += weights[:los_score]
      weights[:los_score] = 0
      filters[:los_score] = 0
      options[:filtering_los] = false
    end
    if options[:user].blank?
      if options[:lo]
        weights[:los_score] += weights[:us_score]
      else
        weights_sum = (weights_sum-weights[:us_score])
      end
      weights[:us_score] = 0
      filters[:us_score] = 0
      options[:filtering_us] = false
    end
    
    weights.each{ |k, v| weights[k] = [1,v/weights_sum.to_f].min } if (weights_sum < 1 and weights_sum > 0)

    #Check if any individual filtering should be performed
    if options[:filtering_los].nil?
      options[:filters_los] = getLoSFilters(options)
      options[:filtering_los] = options[:filters_los].map {|k,v| v}.sum > 0
    end
    if options[:filtering_us].nil?
      options[:filters_us] = getUSFilters(options)
      options[:filtering_us] = options[:filters_us].map {|k,v| v}.sum > 0
    end

    calculateLoSimilarityScore = ((weights[:los_score]>0)||(filters[:los_score]>0)||options[:filtering_los])
    calculateUserSimilarityScore = ((weights[:us_score]>0)||(filters[:us_score]>0)||options[:filtering_us] )
    calculateQualityScore = ((weights[:quality_score]>0)||(filters[:quality_score]>0))
    calculatePopularityScore = ((weights[:popularity_score]>0)||(filters[:popularity_score]>0))

    preSelectionLOs.map{ |lo|
      lo.tag_array_cached = lo.tag_array
      
      los_score = calculateLoSimilarityScore ? loSimilarityScore(options[:lo],lo,options) : 0
      (lo.filtered=true and next) if (calculateLoSimilarityScore and los_score < filters[:los_score])
      
      us_score = calculateUserSimilarityScore ? userSimilarityScore(options[:user],lo,options) : 0
      (lo.filtered=true and next) if (calculateUserSimilarityScore and us_score < filters[:us_score])
      
      quality_score = calculateQualityScore ? qualityScore(lo) : 0
      (lo.filtered=true and next) if (calculateQualityScore and quality_score < filters[:quality_score])
      
      popularity_score = calculatePopularityScore ? popularityScore(lo) : 0
      (lo.filtered=true and next) if (calculatePopularityScore and popularity_score < filters[:popularity_score])

      lo.score = weights[:los_score] * los_score + weights[:us_score] * us_score + weights[:quality_score] * quality_score + weights[:popularity_score] * popularity_score
    
      # lo.score_tracking = {
      #   :cs_score => los_score.round(2),
      #   :us_score => us_score.round(2),
      #   :popularity_score => popularity_score.round(2),
      #   :quality_score => quality_score.round(2),
      #   :weights => weights,
      #   :overall_score => lo.score.round(2),
      #   :object_id => lo.id,
      #   :object_type => lo.object_type,
      #   :qscore => lo.qscore,
      #   :popularity => lo.popularity
      # }
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
    weights = options[:weights_los] || getLoSWeights(options)
    filters = options[:filtering_los]!=false ? (options[:filters_los] || getLoSFilters(options)) : nil

    titleS = getSemanticDistance(loA.title,loB.title)
    descriptionS = weights[:description] > 0 ? getSemanticDistance(loA.description,loB.description) : 0
    languageS = getSemanticDistanceForLanguage(loA.language,loB.language)
    keywordsS = getSemanticDistanceForKeywords(loA.tag_array_cached,loB.tag_array_cached)

    return -1 if (!filters.blank? and (titleS < filters[:title] || descriptionS < filters[:description] || languageS < filters[:language] || keywordsS < filters[:keywords]))

    return weights[:title] * titleS + weights[:description] * descriptionS + weights[:language] * languageS + weights[:keywords] * keywordsS
  end

  #User profile Similarity Score, [0,1] scale
  def self.userSimilarityScore(user,lo,options={})
    weights = options[:weights_us] || getUSWeights(options)
    filters = options[:filtering_us]!=false ? (options[:filters_us] || getUSFilters(options)) : nil
    
    languageS = getSemanticDistanceForLanguage(user.language,lo.language)
    keywordsS = getSemanticDistanceForKeywords(user.tag_array_cached,lo.tag_array_cached)

    losS = 0
    unless options[:user_los].blank?
      options[:user_los].each do |pastLo|
        losS += loSimilarityScore(pastLo,lo,options.merge({:filtering_los => false}))
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
    keywords += options[:user].tag_array_cached unless options[:user].nil?
    #Resource tags
    keywords += options[:lo].tag_array_cached unless options[:lo].nil?
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
    return 0 if (textA.blank? or textB.blank?)

    #We need to limit the length of the text due to performance issues
    textA = textA.first(Vish::Application::config.rs_max_text_length)
    textB = textB.first(Vish::Application::config.rs_max_text_length)

    numerator = 0
    denominator = 0
    denominatorA = 0
    denominatorB = 0

    wordsTextA = processFreeText(textA)
    wordsTextB = processFreeText(textB)

    (wordsTextA.keys + wordsTextB.keys).uniq.each do |word|
      wordIDF = IDF(word)
      tfidf1 = (wordsTextA[word] || 0) * wordIDF
      tfidf2 = (wordsTextB[word] || 0) * wordIDF
      numerator += (tfidf1 * tfidf2)
      denominatorA += tfidf1**2
      denominatorB += tfidf2**2
    end

    denominator = Math.sqrt(denominatorA) * Math.sqrt(denominatorB)
    return 0 if denominator==0

    numerator/denominator
  end

  def self.processFreeText(text)
    return {} if text.blank?
    words = Hash.new
    normalizeText(text).split(" ").each do |word|
      words[word] = 0 if words[word].nil?
      words[word] += 1
    end
    words
  end

  def self.normalizeText(text)
    I18n.transliterate(text.gsub(/([\n])/," ").strip, :locale => "en").downcase
  end

  # Term Frequency (TF)
  def self.TF(word,text)
    processFreeText(text)[normalizeText(word)] || 0
  end

  # Inverse Document Frequency (IDF)
  def self.IDF(word)
    Math::log(Vish::Application::config.rs_repository_total_entries/(1+(Vish::Application::config.rs_words[word] || 0)).to_f)
  end

  # TF-IDF
  def self.TFIDF(word,text)
    tf = TF(word,text)
    return 0 if tf==0
    return (tf * IDF(word))
  end

  #Semantic distance between text arrays (in a 0-1 scale)
  def self.getTextArraySemanticDistance(textArrayA,textArrayB)
    return 0 if textArrayA.blank? or textArrayB.blank?
    return 0 unless textArrayA.is_a? Array and textArrayB.is_a? Array

    return getSemanticDistance(textArrayA.join(" "),textArrayB.join(" "))
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for categorical fields.
  #Return 1 if both fields are equal, 0 if not.
  def self.getSemanticDistanceForCategoricalFields(stringA,stringB)
    stringA = normalizeText(stringA) rescue nil
    stringB = normalizeText(stringB) rescue nil
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
  #It calculates the semantic distance for languages.
  def self.getSemanticDistanceForLanguage(stringA,stringB)
    return 0 if ["independent","ot"].include? stringA
    return getSemanticDistanceForCategoricalFields(stringA,stringB)
  end

  #Semantic distance in a [0,1] scale.
  #It calculates the semantic distance for keywords.
  def self.getSemanticDistanceForKeywords(keywordsA,keywordsB)
    return 0 if keywordsA.blank? or keywordsB.blank?
    # keywordsA = keywordsA.map{|k| normalizeText(k)}.uniq
    # keywordsB = keywordsB.map{|k| normalizeText(k)}.uniq
    return (2*(keywordsA & keywordsB).length)/(keywordsA.length+keywordsB.length).to_f
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
      vishRSConfig = (settingFamily=="weights") ? Vish::Application::config.rs_weights : Vish::Application::config.rs_filters
      userSettings = vishRSConfig[defaultKey]
    end

    userSettings.recursive_merge({})
  end


  # Default weights for the Recommender System provided by ViSH
  # These weights can be overriden in the application_config.yml file.
  # The current default weights can be accesed in the Vish::Application::config.rs_weights variable.
  def self.defaultRSWeights
    {
      :los_score => 0.6,
      :us_score => 0.2,
      :quality_score => 0.1,
      :popularity_score => 0.1
    }
  end

  def self.defaultLoSWeights
    {
      :title => 0.2,
      :description => 0.1,
      :language => 0.5,
      :keywords => 0.2
    }
  end

  def self.defaultUSWeights
    {
      :language => 0.25,
      :keywords => 0.25,
      :los => 0.5
    }
  end

  # Default filters for the Recommender System provided by ViSH
  # These filters can be overriden in the application_config.yml file.
  # The current default filters can be accesed in the Vish::Application::config.rs_filters variable.
  def self.defaultRSFilters
    {
      :los_score => 0,
      :us_score => 0,
      :quality_score => 0.3,
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