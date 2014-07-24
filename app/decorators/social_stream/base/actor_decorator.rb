Actor.class_eval do

  before_save :fix_relation_ids

  # Activities are shared publicly by default
  def activity_relations
    [ Relation::Public.instance ]
  end

  def fix_relation_ids
    if self.activity_object.relation_ids.blank?
      if self.is_admin
        self.activity_object.relation_ids=[Relation::Private.instance.id]
      else
        self.activity_object.relation_ids=[Relation::Public.instance.id]
      end
    end
    # if self.relation_ids.blank?
    #   self.relation_ids=[Relation::Public.instance.id]
    # end
  end

end
