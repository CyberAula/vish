# encoding: utf-8

###############
# ViSH Recommender System (and Search Engine)
###############

class RecommenderSystem

  def self.resource_suggestions(options={})
#subject=nil,resource=nil, now its user, lo

    # Step 0: Initialize all variables
    options = prepareOptions(options)

    #Step 1: Preselection
    preSelectionLOs = getPreselection(subject,resource,options)

    #Step 2: Scoring
    rankedLOs = orderByScore(preSelectionLOs,subject,resource,options)

    #Step 3
    return rankedLOs.first(options[:n])
  end

  # Step 0: Initialize all variables
  def self.prepareOptions(options={})
    options = {:n => 20, :settings => Vish::Application::config.default_settings}.recursive_merge(options)
    options[:models] = VishConfig.getAvailableResourceModels({:return_instances => true}) if options[:models].blank?
    options[:model_names] = options[:models].map{|m| m.name}
    unless options[:user].blank?
      options[:user_los] = [] #TODO. Get and limit LOs from user
      options[:user_los] = options[:user_los].first(options[:max_user_los] || Vish::Application::config.max_user_los)
    end
    options
  end

  #Step 1: Preselection
  def self.getPreselection(subject,resource,options={})
    preSelection = []

    if options[:recEngine] == "Random"
      return Excursion.where(:draft=>false).sample(options[:n])
    end

    #Search resources using the search engine

    #Filter resources by language
    if !resource.nil?
      #Recommending resources similar to other resource
      options[:language] = resource.language unless [nil,"independent","ot"].include? resource.language
    elsif !subject.nil?
      #Recommending resources to a user
      options[:language] = subject.language unless [nil,"independent","ot"].include? subject.language
    end

    keywords = compose_keywords(subject,resource,options)
    unless keywords.blank? and options[:language].blank?
      searchEngineResources = (Search.search search_options(keywords,subject,resource,options)).compact rescue []
      preSelection.concat(searchEngineResources)
    end

    #Add other resources of the same author
    unless options[:test] or resource.nil? or resource.author.nil?
      unless (((!subject.nil?) ? Actor.normalize_id(subject) : -1) == resource.author.id)
        authoredResources = ActivityObject.where("scope=0 and object_type IN (?) and activity_objects.id not IN (?)",options[:model_names], resource.activity_object.id).authored_by(resource.author).map{|ao| ao.object}.compact
        preSelection.concat(authoredResources)
        preSelection.uniq!
      end
    end

    pSL = preSelection.length

    if options[:random]
      #Random: fill to Nmax, and select 2/3Nmax randomly
      if pSL < options[:nMax]
        preSelection.concat(getResourcesToFill(options[:nMax]-pSL,preSelection,subject,resource,options))
      end
      sampleSize = (options[:nMax]*2/3.to_f).ceil
      preSelection = preSelection.sample(sampleSize)
    else
      if pSL < options[:n]
        preSelection.concat(getResourcesToFill(options[:n]-pSL,preSelection,subject,resource,options))
      end
      preSelection = preSelection.first(options[:nMax])
    end

    return preSelection
  end

  #Step 2: Scoring
  def self.orderByScore(preSelectionLOs,subject,resource,options)

    if preSelectionLOs.blank?
      return preSelectionLOs
    end

    #Get some vars to normalize scores
    maxPopularity = preSelectionLOs.max_by {|e| e.popularity }.popularity
    maxQuality = preSelectionLOs.max_by {|lo| lo.qscore }.qscore

    calculateCSScore = !resource.nil?
    calculateUSScore = !subject.nil?
    calculatePopularityScore = !(maxPopularity.nil? or maxPopularity == 0)
    calculateQualityScore = !(maxQuality.nil? or maxQuality == 0)

    weights = {}

    if calculateCSScore
      #Recommend resources similar to other resource
      weights[:cs_score] = 0.70
      weights[:us_score] = 0.10
      weights[:popularity_score] = 0.10
      weights[:quality_score] = 0.10
    elsif calculateUSScore
      #Recommend resources for a user (or subject)
      weights[:cs_score] = 0.0
      weights[:us_score] = 0.80
      weights[:popularity_score] = 0.10
      weights[:quality_score] = 0.10
    else
      #Recommend resources for anonymous users
      weights[:cs_score] = 0.0
      weights[:us_score] = 0.0
      weights[:popularity_score] = 0.5
      weights[:quality_score] = 0.5
    end

    preSelectionLOs.map{ |lo|
      if calculateCSScore
        cs_score = RecommenderSystem.contentSimilarityScore(resource,lo)
      else
        cs_score = 0
      end

      if calculateUSScore
        us_score = RecommenderSystem.userProfileSimilarityScore(subject,lo)
      else
        us_score = 0
      end

      if calculatePopularityScore
        popularity_score = RecommenderSystem.popularityScore(lo,maxPopularity)
      else
        popularity_score = 0
      end

      if calculateQualityScore
        quality_score = RecommenderSystem.qualityScore(lo,maxQuality)
      else
        quality_score = 0
      end

      lo.score = weights[:cs_score] * cs_score + weights[:us_score] * us_score + weights[:popularity_score] * popularity_score + weights[:quality_score] * quality_score
      
      if options[:recEngine] == "ViSHRS-Quality"
        lo.score -= weights[:quality_score] * quality_score
      elsif options[:recEngine] == "ViSHRS-Quality-Popularity"
        lo.score -= weights[:quality_score] * quality_score + weights[:popularity_score] * popularity_score
      end

      unless options[:test]
        lo.score_tracking = {
          :cs_score => cs_score,
          :us_score => us_score,
          :popularity_score => popularity_score,
          :quality_score => quality_score,
          :weights => weights,
          :overall_score => lo.score,
          :object_id => lo.id,
          :object_type => lo.object_type,
          :qscore => lo.qscore,
          :popularity => lo.popularity,
          :rec => options[:recEngine]
        }.to_json
      end
    }

    if options[:recEngine] == "Random"
      return preSelectionLOs
    end

    preSelectionLOs.sort! { |a,b|  b.score <=> a.score }
  end

  #Content Similarity Score (between 0 and 1)
  def self.contentSimilarityScore(loA,loB)
    weights = {}
    weights[:language] = 0.5
    weights[:keywords] = 0.3
    weights[:title] = 0.2

    languageD = RecommenderSystem.getSemanticDistance(loA.language,loB.language)
    keywordsD = RecommenderSystem.getTextArraySemanticDistance(loA.tag_list.to_a,loB.tag_list.to_a)
    titleD = RecommenderSystem.getSemanticDistance(loA.title,loB.title)
    
    return weights[:language] * languageD + weights[:keywords] * keywordsD + weights[:title] * titleD
  end

  #User profile Similarity Score (between 0 and 1)
  def self.userProfileSimilarityScore(subject,lo)
    weights = {}
    weights[:language] = 0.75
    weights[:keywords] = 0.25

    unless ["independent","ot"].include? lo.language
      languageD = RecommenderSystem.getSemanticDistance(subject.language,lo.language)
    else
      languageD = 0
    end
    keywordsD = RecommenderSystem.getTextArraySemanticDistance(subject.tag_list.to_a,lo.tag_list.to_a)

    return weights[:language] * languageD + weights[:keywords] * keywordsD
  end

  #Popularity Score (between 0 and 1)
  #See scheduled:recalculatePopularity task in lib/tasks/scheduled.rake to adjust popularity weights
  def self.popularityScore(lo,maxPopularity)
    return lo.popularity/maxPopularity.to_f
  end

  #Quality Score (between 0 and 1)
  #See app/decorators/social_stream/base/activity_object_decorator.rb, method calculate_qscore to adjust weights
  def self.qualityScore(lo,maxQualityScore)
    return lo.qscore/maxQualityScore.to_f
  end


  private

  #######################
  ## Utils (private methods)
  #######################

  def self.compose_keywords(subject,resource,options={})
    maxKeywords = 25
    keywords = []
    
    #Subject tags (i.e. user tags)
    if !subject.nil?
      keywords += subject.tag_list
    end

    #Resource tags
    if !resource.nil?
      keywords += resource.tag_list
    end

    #Keywords specified in the options
    if options[:keywords].is_a? Array
      keywords += options[:keywords]
    end

    keywords.uniq!

    if options[:test]
      return keywords
    end

    #If keywords are least than the maxKeywords, fill it with additional data about the subject
    if !subject.nil?
      keywordsMargin = maxKeywords - keywords.length
      if keywordsMargin > 0
        #Tags of the resources the subject created
        allAuthoredKeywords = ActivityObject.where("scope=0 and object_type IN (?)",options[:model_names]).authored_by(subject).map{ |r| r.tag_list }.flatten.uniq
        keywords = keywords + allAuthoredKeywords.sample(keywordsMargin)
        keywords.uniq!
      end

      keywordsMargin = maxKeywords - keywords.length
      if keywordsMargin > 0
        #Tags of the resources the subject like
        allLikedKeywords = Activity.joins(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id, :author_id => Actor.normalize_id(subject)}).where("activity_objects.scope=0 and activity_objects.object_type IN (?)", options[:model_names]).map{ |activity| activity.activity_objects.first.tag_list }.flatten.uniq
        keywords = keywords + allLikedKeywords.sample(keywordsMargin)
        keywords.uniq!
      end
    end

    #Remove unuseful keywords
    keywords.delete_if{|el| ["ViSHCompetition2013"].include? el or el.length < 2}

    return keywords
  end



  def self.search_options(keywords,subject,resource,options={})
    opts = {}
    opts[:n] = options[:nMax]

    unless keywords.blank?
      opts[:keywords] = keywords
    end

    #Only search for desired models
    opts[:models] = options[:models]

    unless subject.nil?
      opts[:subjects_to_avoid] = [subject]
    end

    unless resource.nil?
      opts[:ao_ids_to_avoid] = [resource.activity_object.id]
    end

    unless options[:language].nil?
      opts[:language] = options[:language]
    end

    return opts
  end

  def self.getResourcesToFill(n,preSelection,subject,resource,options)
    resources = []
    nSubset = [80,4*n].max
    ids_to_avoid = getIdsToAvoid(preSelection,subject,resource,options)
    resources = ActivityObject.where("scope=0 and object_type IN (?) and id not in (?)", options[:model_names], ids_to_avoid)

    unless options[:language].blank?
      langResources = resources.where("language='" + options[:language] + "'")
      if langResources.length >= n
        resources = langResources
      end
    end

    resources.order("ranking DESC").limit(nSubset).sample(n).map{|ao| ao.object}.compact
  end

  def self.getIdsToAvoid(preSelection,subject,resource,options)
    ids_to_avoid = preSelection.map{|e| e.activity_object.id}

    if !resource.nil?
      ids_to_avoid.push(resource.activity_object.id)
    end

    if !subject.nil?
      ids_to_avoid.concat(ActivityObject.where("scope=0 and object_type IN (?)",options[:model_names]).authored_by(subject).map{|r| r.id})
    end

    ids_to_avoid.uniq!

    if !ids_to_avoid.is_a? Array or ids_to_avoid.empty?
      #if ids=[] the queries may returns [], so we fill it with an invalid id (no resource will ever have id=-1)
      ids_to_avoid = [-1]
    end

    return ids_to_avoid
  end


  private

  #######################
  ## Utils (private methods)
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