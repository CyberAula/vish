class Actor
  def suggestions(size=1)
    sgs = (
     RecsysUser.
       find_all_by_id(Actor.last.id).
       map { |u| RecsysUser.find_all_by_clusterid(u.clusterid) }.
       flatten.
       sort_by!{ |u| u.position}.
       map{ |u| u.actor }.
       compact &
     Actor.
       where(Actor.arel_table[:id].not_in(sent_active_contact_ids + [id]))
    ).first(size).map { |a| contact_to! a }

    candidates = Actor.where(Actor.arel_table[:id].not_in(sent_active_contact_ids + [id]))

    sgs + (size - sgs.size).times.map {
      candidates.delete_at rand(candidates.size)
    }.compact.map { |a|
      contact_to! a
    }
  end
end

