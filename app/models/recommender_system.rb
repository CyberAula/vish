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
    preSelection = []
    n = getN(options)
    nMax = getNMax(n)

    keywords = compose_keywords(user,excursion,options)
    searchTerms = keywords.join(" ")
    searchEngineExcursions = (Excursion.search searchTerms, search_options(user,excursion,n,nMax,options)).select{|e| !e.nil?} rescue []
    preSelection.concat(searchEngineExcursions)

    pSL = preSelection.length
    if pSL < n
      preSelection.concat(getExcursionsToFill(n-pSL,preSelection.map{|e| e.id}))
    end

    return preSelection.sample(2)
  end

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


  private


  def self.search_options(user,excursion,n,nMax,options=nil)
    opts = {}

    #Logical conector: OR
    opts[:match_mode] = :any
    opts[:rank_mode] = :wordcount
    opts[:per_page] = nMax
    opts[:field_weights]= {
       :title => 50, 
       :tags => 40,
       :description => 1
    }
    opts[:with] = {}
    opts[:with][:draft] = false

    if !user.nil?
      opts[:without] = {}
      opts[:without][:author_id] = [user.id]
    end

    return opts
  end

  def self.getN(options)
    if !options.nil? and options[:n].is_a? Integer
      n = options[:n]
    else
      #Default value
      n = 20
    end
    n
  end

  def self.getNMax(n)
    if n<10
      nMax = 30
    else
      nMax = 3*n
    end
    nMax
  end

  def self.getExcursionsToFill(n,ids=nil)
    excursions = []
    nSubset = [80,4*n].max
    if !ids.is_a? Array
      ids = []
    end

    excursions = Excursion.joins(:activity_object).where("excursions.draft=false and excursions.id not in (?)", ids).order("activity_objects.popularity DESC").limit(nSubset).sample(n)
  end

end