Actor.class_eval do

  # Activities are shared publicly by default
  def activity_relations
    [ Relation::Public.instance ]
  end
end
