# encoding: utf-8

###############
# ViSH Recommender System (and Search Engine)
###############

class RecommenderSystem

  def self.resource_suggestions(subject=nil,resource=nil,options={})

    # Step 0: Initialize all variables (N,NMax,random,...)
    options = prepareOptions(options)

    #Step 1: Preselection
    preSelectionLOs = getPreselection(subject,resource,options)

    #Step 2: Scoring
    rankedLOs = orderByScore(preSelectionLOs,subject,resource,options)

    #Step 3
    return rankedLOs.first(options[:n])
  end

  # Step 0: Initialize all variables (N,NMax,random,...)
  def self.prepareOptions(options={})
    #Performance test
    if options[:test]==true
      return options
    else
      options[:test] = false
    end

    unless options[:n].is_a? Integer
      options[:n] = 20
    end

    unless options[:random] == false
      options[:random] = true
    end

    #NMax
    if options[:n]<10
      options[:nMax] = 30
    else
      options[:nMax] = 3*options[:n]
    end

    #Models
    if options[:models].blank?
      #All resources by default
      options[:models] = VishConfig.getAvailableResourceModels({:return_instances => true})
    end

    options[:model_names] = options[:models].map{|m| m.name}

    unless options[:recEngine].is_a? String
      options[:recEngine] = "ViSHRecommenderSystem"
    end

    if options[:track].blank?
      options[:track] = false
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
    # nMetadataFields = weights.length

    unless ["independent","ot"].include? loA.language
      languageD = RecommenderSystem.getSemanticDistance(loA.language,loB.language)
    else
      languageD = 0
    end

    keywordsD = RecommenderSystem.getKeywordsDistance(loA.tag_list.to_a.delete_if{|e| e=="ViSHCompetition2013"},loB.tag_list.to_a)
    titleD = RecommenderSystem.getKeywordsDistance(loA.title.split(" ").reject{|w| w.length<3},loB.title.split(" ").reject{|w| w.length<3})
    
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
    keywordsD = RecommenderSystem.getKeywordsDistance(subject.tag_list.to_a,lo.tag_list.to_a)

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

  #############
  # Utils to calculate LO similarity and User Profile similarity
  #############

  #Semantic distance (between 0 and 1)
  def self.getSemanticDistance(stringA,stringB)
    if stringA.blank? or stringB.blank?
      return 0
    end

    stringA =  I18n.transliterate(stringA.downcase.strip)
    stringB =  I18n.transliterate(stringB.downcase.strip)

    if stringA == stringB
      return 1
    else
      return 0
    end
  end

  #Semantic distance between keyword arrays (in a 0-1 scale)
  def self.getKeywordsDistance(keywordsA,keywordsB)
    if keywordsA.blank? or keywordsB.blank?
      return 0
    end 

    similarKeywords = 0
    kParam = [keywordsA.length,keywordsB.length].min

    keywordsA.each do |kA|
      keywordsB.each do |kB|
        if getSemanticDistance(kA,kB) == 1
          similarKeywords += 1
          break
        end
      end
    end

    return similarKeywords/kParam.to_f
  end

end