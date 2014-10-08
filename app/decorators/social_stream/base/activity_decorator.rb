Activity.class_eval do
  scope :timeline, lambda { |senders = nil, receivers = nil|
    if senders == :home
      senders = receivers.following_actor_and_self_ids
    end

    activities = select("DISTINCT activities.*").
      roots.
      includes(:author, :user_author, :owner, :activity_objects, :activity_verb, :relations).
      authored_or_owned_by(senders).
      shared_with(receivers).
      joins(:activity_objects).where("activity_objects.scope=0").
      order("activities.created_at desc")
  }
end