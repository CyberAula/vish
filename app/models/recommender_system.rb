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
    keywords = compose_keywords(user,excursion,options)



    popularExcursions = Excursion.joins(:activity_object).order("activity_objects.popularity DESC").select{|ex| ex.draft == false}
    return popularExcursions.sample(2)
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

  # def self.excursion_suggestions(user,excursion,options)
  #   excursions = []
  #   cExcursionId = nil

  #   if params[:excursion_id]
  #     current_excursion =  Excursion.find(params[:excursion_id]) rescue nil
  #     cExcursionId = current_excursion.id rescue nil
  #   end

  #   if params[:q]
  #     searchTerms = params[:q].split(",")
  #   else
  #     searchTerms = []
  #   end

  #   #Add excursions based on the current excursion
  #   if !current_excursion.nil?

  #     if !current_excursion.tag_list.empty?
  #       searchTerms.concat(current_excursion.tag_list)
  #     end

  #     if !current_excursion.author.nil?
  #       authorExcursions = ActivityObject.where(:object_type=>"Excursion").select{ |e| e.author_id == current_excursion.author.id }.map { |ao| ao.excursion }.select{|e| e.id != current_excursion.id and e.draft == false}
  #       #Limit the number of authorExcursions
  #       authorExcursions = authorExcursions.sample(2)
  #       excursions.concat(authorExcursions)
  #     end

  #   end

  #   searchTerms.uniq!
  #   searchTerms = searchTerms.join(",")
  #   relatedExcursions = (Excursion.search searchTerms, search_options).map {|e| e}.select{|e| e.id != cExcursionId and e.draft == false} rescue []
  #   excursions.concat(relatedExcursions)

  #   #Remove drafts and current excursion
  #   excursions.uniq!
  #   excursions = excursions.select{|ex| ex.draft == false}.reject{ |ex| ex.id == cExcursionId }

  #   #Fill excursions (until 6), with popular excursions
  #   holes = [0,6-excursions.length].max
  #   if holes > 0
  #     popularExcursions = Excursion.joins(:activity_object).order("activity_objects.popularity DESC").select{|ex| ex.draft == false}.reject{ |ex| excursions.map{ |fex| fex.id }.include? ex.id || (!current_excursion.nil? and ex.id == current_excursion.id) }
  #     popularExcursions.in_groups_of(80){ |group|
  #       popularExcursions = group
  #       break
  #     }
  #     excursions.concat(popularExcursions.sample(holes))
  #   end
  #   excursions = excursions.sample(6)

  #   respond_to do |format|
  #     format.json { 
  #       results = []
  #       excursions.map { |ex| results.push(ex.reduced_json(self)) }
  #       render :json => results
  #     }
  #   end
  # end

  # private

  # def search_options
  #   opts = search_scope_options

  #   # Allow me to search only one type
  #   opts.deep_merge!({
  #     :conditions => { :excursion_type => params[:type] }
  #   }) unless params[:type].blank?

  #   # Pagination
  #   opts.deep_merge!({
  #     :order => :created_at,
  #     :sort_mode => :desc,
  #     :per_page => params[:per_page] || 20,
  #     :page => params[:page]
  #   })

  #   opts
  # end

  # def search_subject
  #   return current_subject if request.referer.blank?
  #   @search_subject ||=
  #     ( Actor.find_by_slug(URI(request.referer).path.split("/")[2]) || current_subject )
  # end

  # def search_scope_options
  #   if params[:scope].blank? || search_subject.blank?
  #     return {}
  #   end

  #   case params[:scope]
  #   when "me"
  #     if user_signed_in? and (search_subject == current_subject)
  #       { :with => { :author_id => [ search_subject.id ] } }
  #     else
  #       { :with => { :author_id => [ search_subject.id ], :draft => false } }
  #     end
  #   when "net"
  #     { :with => { :author_id => search_subject.following_actor_ids, :draft => false } }
  #   when "other"
  #     { :without => { :author_id => search_subject.following_actor_and_self_ids }, :with => { :draft => false } }
  #   else
  #     raise "Unknown search scope #{ params[:scope] }"
  #   end
  # end

end