class ActorHistorial < ActiveRecord::Base
  set_table_name 'actor_historial'
  belongs_to :actor
  belongs_to :activity_object

  validates :activity_object_id, :uniqueness => {:scope => :actor_id}

  #Stores the last 5 activity objects visited by the actor
  def self.saveAO(actor,ao)
    return if actor.nil? or ao.nil?
    ao = ao.activity_object if ao.respond_to?("activity_object")
    return unless ao.resource?

    pastAOs = actor.past_activity_objects
    aoIndex = pastAOs.index(ao)
    if aoIndex.nil?
      #4 should be the maximum length - 1
      pastAOs = pastAOs.last(4).push(ao)
    elsif aoIndex==(pastAOs.length-1)
      #ao is already at last position, no action needed
      return
    else
      pastAOs = (pastAOs-[ao])
      actor.past_activity_objects = pastAOs
      pastAOs.push(ao)
    end
    actor.past_activity_objects = pastAOs
  end
end