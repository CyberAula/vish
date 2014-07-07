# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

# ViSH Recommender System

class RecommenderSystem

  def self.excursion_suggestions(user,excursion,options=nil)
    # Step 0: Initialize all variables (N,NMax,random,...)
    options = prepareOptions(options)

    #Step 1: Preselection
    preSelectionLOs = getPreselection(user,excursion,options)

    #Step 2: Scoring
    rankedLOs = orderByScore(preSelectionLOs,user,excursion,options)

    #Step 3
    return rankedLOs.first(options[:n])
  end

  # Step 0: Initialize all variables (N,NMax,random,...)
  def self.prepareOptions(options=nil)
    if !options.nil?
      unless options[:n].is_a? Integer
        options[:n] = 20
      end
      unless options[:random] == false
        options[:random] = true
      end
    else
      options = {}

      #Default values
      options[:n] = 20
      options[:random] = true
    end

    #NMax
    if options[:n]<10
      options[:nMax] = 30
    else
      options[:nMax] = 3*options[:n]
    end

    options
  end

  #Step 1: Preselection
  def self.getPreselection(user,excursion,options=nil)
    preSelection = []

    #Search excursions using the search engine
    keywords = compose_keywords(user,excursion,options)
    if !keywords.empty?
      searchTerms = keywords.join(" ")
      searchEngineExcursions = (Excursion.search searchTerms, search_options(user,excursion,options)).select{|e| !e.nil?} rescue []
      preSelection.concat(searchEngineExcursions)
    end

    #Add other excursions of the same author
    if !excursion.nil?
      userIdToReject = (!user.nil?) ? user.id : -1
      authoredExcursions = Excursion.authored_by(excursion.author).reject{|e| e.draft == true or e.author_id == userIdToReject or e.id == excursion.id}
      preSelection.concat(authoredExcursions)
      preSelection.uniq!
    end

    pSL = preSelection.length

    if options[:random]
      #Random: fill to Nmax, and select 2/3Nmax randomly
      if pSL < options[:nMax]
        preSelection.concat(getExcursionsToFill(options[:nMax]-pSL,preSelection,user,excursion,options))
      end
      sampleSize = (options[:nMax]*2/3.to_f).ceil
      preSelection = preSelection.sample(sampleSize)
    else
      if pSL < options[:n]
        preSelection.concat(getExcursionsToFill(options[:n]-pSL,preSelection,user,excursion,options))
      end
      preSelection = preSelection.first(options[:nMax])
    end

    return preSelection
  end

  #Step 2: Scoring
  def self.orderByScore(preSelectionLOs,user,excursion,options)

    #Get some vars to normalize scores
    maxPopularity = preSelectionLOs.max_by {|e| e.popularity }.popularity

    #We need to filter LOs without qscore attribute, because BigDecimal (qscore) can't be compared against nil
    preSelectionLOsWithQuality = preSelectionLOs.reject{|lo| lo.qscore.nil?}
    unless preSelectionLOsWithQuality.empty?
      maxQuality = preSelectionLOsWithQuality.max_by {|e| e.qscore }.qscore
    else
      maxQuality = nil
    end

    weights = {}
    weights[:cs_score] = 0.60
    weights[:ups_score] = 0.15
    weights[:popularity_score] = 0.10
    weights[:quality_score] = 0.15

    calculateCSScore = !excursion.nil?
    calculateUPSScore = !user.nil?
    calculatePopularityScore = !(maxPopularity.nil? or maxPopularity == 0)
    calculateQualityScore = !(maxQuality.nil? or maxQuality == 0)

    preSelectionLOs.map{ |e|
      if calculateCSScore
        cs_score = RecommenderSystem.contentSimilarityScore(excursion,e)
      else
        cs_score = 0
      end

      if calculateUPSScore
        ups_score = RecommenderSystem.userProfileSimilarityScore(user,e)
      else
        ups_score = 0
      end

      if calculatePopularityScore
        popularity_score = RecommenderSystem.popularityScore(e,maxPopularity)
      else
        popularity_score = 0
      end

      if calculateQualityScore
        quality_score = RecommenderSystem.qualityScore(e,maxQuality)
      else
        quality_score = 0
      end

      e.score = weights[:cs_score] * cs_score + weights[:ups_score] * ups_score + weights[:popularity_score] * popularity_score + weights[:quality_score] * quality_score
      e.score_tracking = {
        :cs_score => cs_score,
        :ups_score => ups_score,
        :popularity_score => popularity_score,
        :quality_score => quality_score,
        :overall_score => e.score,
        :rec => "ViSHRecommenderSystem"
      }.to_json
    }

    preSelectionLOs.sort! { |a,b|  b.score <=> a.score }
  end

  #Content Similarity Score (between 0 and 1)
  def self.contentSimilarityScore(loA,loB)
    weights = {}
    weights[:language] = 0.6
    weights[:keywords] = 0.4
    # nMetadataFields = weights.length

    languageD = RecommenderSystem.getSemanticDistance(loA.language,loB.language)
    keywordsD = RecommenderSystem.getKeywordsDistance(loA.tag_list,loB.tag_list)

    return weights[:language] * languageD + weights[:keywords] * keywordsD
  end

  #User profile Similarity Score (between 0 and 1)
  def self.userProfileSimilarityScore(user,lo)
    weights = {}
    weights[:language] = 0.6
    weights[:keywords] = 0.4

    languageD = RecommenderSystem.getSemanticDistance(user.language,lo.language)
    keywordsD = RecommenderSystem.getKeywordsDistance(user.tag_list,lo.tag_list)

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
    if lo.qscore.nil?
      return 0
    else
      return lo.qscore/maxQualityScore.to_f
    end
  end


  private

  def self.compose_keywords(user,excursion,options=nil)
    maxKeywords = 25
    keywords = []
    
    #User tags
    if !user.nil?
      keywords = keywords + user.tag_list
    end

    #Excursion tags
    if !excursion.nil?
      keywords = keywords + excursion.tag_list
    end

    #Keywords specified in the options
    if !options.nil? and options[:keywords].is_a? Array
      keywords = keywords + options[:keywords]
    end

    keywords.uniq!

    #If keywords are least than the maxKeywords, fill it with additional data about the user
    if !user.nil?
      keywordsMargin = maxKeywords - keywords.length
      if keywordsMargin > 0
        #Tags of the excursions the user created
        allAuthoredKeywords = []
        ActivityObject.where(:object_type=>"Excursion").authored_by(user).map{ |activity_object| activity_object.tag_list }.each do |authoredKeywords|
          allAuthoredKeywords = allAuthoredKeywords + authoredKeywords
        end
        allAuthoredKeywords.uniq!
        keywords = keywords + allAuthoredKeywords.sample(keywordsMargin)
        keywords.uniq!
      end

      keywordsMargin = maxKeywords - keywords.length
      if keywordsMargin > 0
        allLikedKeywords = []
        #Tags of the excursions the user like
        Activity.joins(:activity_objects).includes(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id, :author_id => user.id}).where("activity_objects.object_type IN (?)", ["Excursion"]).map{ |activity| activity.activity_objects.first.tag_list }.each do |likedKeywords|
          allLikedKeywords = allLikedKeywords + likedKeywords
        end
        allLikedKeywords.uniq!

        keywords = keywords + allLikedKeywords.sample(keywordsMargin)
        keywords.uniq!
      end
    end

    #Remove unuseful keywords
    keywords.delete_if{|el| el=="ViSHCompetition2013"}

    return keywords
  end

  def self.search_options(user,excursion,options=nil)
    opts = {}

    #Logical conector: OR
    opts[:match_mode] = :any
    opts[:rank_mode] = :wordcount
    opts[:per_page] = options[:nMax]
    opts[:field_weights]= {
       :title => 50, 
       :tags => 40,
       :description => 1
    }
    opts[:with] = {}
    opts[:with][:draft] = false

    if !user.nil? or !excursion.nil?
      opts[:without] = {}
      if !user.nil?
        opts[:without][:author_id] = [user.id]
      end
      if !excursion.nil?
        opts[:without][:id] = [excursion.id]
      end
    end

    return opts
  end

  def self.getExcursionsToFill(n,preSelection,user,excursion,options=nil)
    excursions = []
    nSubset = [80,4*n].max
    ids_to_avoid = getIdsToAvoid(preSelection,user,excursion,options)
    excursions = Excursion.joins(:activity_object).where("excursions.draft=false and excursions.id not in (?)", ids_to_avoid).order("activity_objects.popularity DESC").limit(nSubset).sample(n)
  end

  def self.getIdsToAvoid(preSelection,user,excursion,options=nil)
    ids_to_avoid = preSelection.map{|e| e.id}

    if !user.nil?
      ids_to_avoid.concat(Excursion.authored_by(user).map{|e| e.id})
    end

    if !excursion.nil?
      ids_to_avoid.push(excursion.id)
    end

    ids_to_avoid.uniq!

    if !ids_to_avoid.is_a? Array or ids_to_avoid.empty?
      #if ids=[] the queries may returns [], so we fill it with an invalid id (no excursion will ever have id=-1)
      ids_to_avoid = [-1]
    end

    return ids_to_avoid
  end

  #############
  # Utils to calculate LO similarity and User Profile similarity
  #############

  #Semantic distance (between 0 and 1)
  def self.getSemanticDistance(stringA,stringB)
    if stringA.nil? or stringB.nil?
      return 0
    end

    stringA =  I18n.transliterate(stringA.downcase.strip)
    stringB =  I18n.transliterate(stringB.downcase.strip)

    if stringA.downcase == stringB
      return 1
    else
      return 0
    end
  end

  #Semantic distance between keyword arrays (in a 0-1 scale)
  def self.getKeywordsDistance(keywordsA,keywordsB)
    if keywordsA.nil? or keywordsB.nil? or keywordsA.empty? or keywordsB.empty?
      return 0
    end 

    similarKeywords = 0
    kParam = [keywordsA.length,keywordsB.length].min

    keywordsA.each do |kA|
      keywordsB.each do |kB|
        if getSemanticDistance(kA,kB) == 1
          similarKeywords = similarKeywords + 1
          break
        end
      end
    end

    return similarKeywords/kParam.to_f
  end

end