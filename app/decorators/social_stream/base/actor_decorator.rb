require 'recsys'

Actor.class_eval do
  include RecSys::ActorRecSys

  # Activities are shared publicly by default
  def activity_relations
    [ Relation::Public.instance ]
  end
end
