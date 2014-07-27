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
  end

  def admin?
    self.is_admin
  end

  #Make the actor admin
  def make_me_admin
    self.is_admin = true

    #prevent the admin to be indexed by the search engine
    self.relation_ids = [Relation::Private.instance.id]
    self.activity_object.relation_ids = [Relation::Private.instance.id]
    self.save!

    #Make the actor admin 'in the Social Stream way'
    contact = Site.current.contact_to!(self)
    contact.user_author = self
    contact.relation_ids = [ Relation::LocalAdmin.instance.id ]
    contact.save!
  end

end
