class Rsevaluation < ActiveRecord::Base
  validates :actor_id, :presence => true, :uniqueness => true
  validates :data, :presence => true
  validates_inclusion_of :status, :in => ["0","1","2","Finished"], :allow_nil => false

  belongs_to :actor


  #Utils for ViSHRS evaluation
  def self.getRandom(options={})
    options[:n] = 20 unless options[:n].is_a? Integer

    # Search random resources using the search engine
    searchOptions = {}
    searchOptions[:n] = options[:n]
    searchOptions[:models] = [Excursion]
    searchOptions[:order] = "random"
    searchOptions[:ao_ids_to_avoid] = options[:ao_ids_to_avoid] unless options[:ao_ids_to_avoid].blank?

    return Search.search(searchOptions).compact
  end

  def self.getLosForActor(actor,n=5)
    #Get liked resources of the user
    likedResources = Activity.joins(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id, :author_id => Actor.normalize_id(actor)}).where("activity_objects.object_type IN (?) and activity_objects.scope=0","Excursion")
    #Get last N liked resources in the last 7 days
    endDate = DateTime.now
    startDate = endDate - 7
    likedResources = likedResources.where(:created_at => startDate..endDate).order("created_at DESC").first(n).map{|a| a.direct_object}
    
    lRl = likedResources.length
    if lRl < n
      #Try to fill with authored resources
      authoredResources = ActivityObject.authored_by(actor).where("activity_objects.object_type IN (?) and activity_objects.scope=0","Excursion")
      #Get more representative or novel resources
      authoredResources = authoredResources.order("qscore DESC, created_at DESC").first(n-lRl).map{|ao| ao.object}
      likedResources += authoredResources
    end

    likedResources
  end

  def self.getActivityObjectJSON(aos)
    if aos.is_a? Array
      return aos.map{|ao| getActivityObjectJSON(ao)}
    else
      ao = aos.respond_to?("activity_object") ? aos.activity_object : aos
      json = {
        :id => ao.id.to_s,
        :type => ao.getType,
        :created_at => ao.created_at.strftime("%d-%m-%Y"),
        :updated_at => ao.updated_at.strftime("%d-%m-%Y"),
        :title => ao.title,
        :description => ao.description,
        :language => ao.language,
        :tags => ao.tag_list
      }
      json[:name] = ao.name if ao.respond_to?("name")
      return json
    end
  end
end