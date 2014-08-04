class Relation::Private < Relation::Single
  PERMISSIONS =
    [
      [ 'read', 'activity' ]
    ]

  # A {Relation::Private private relation} is always the weakest
  def <=>(relation)
    0
  end

  # Are we supporting custom permissions for {Relation::Private}? Not by the moment.
  def allow?(user, action, object)
    action == 'read' && object == 'activity' && (activities.map{|a| a.owner }.include? user.actor)
  end
end
