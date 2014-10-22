Actor.class_eval do

  # Activities are shared publicly by default
  def activity_relations
    [ Relation::Public.instance ]
  end

  def admin?
    self.is_admin
  end

  #Make the actor admin
  def make_me_admin
    self.is_admin = true
    self.activity_object.relation_ids = [Relation::Private.instance.id]
    self.activity_object.scope = 1
    self.save!

    #Make the actor admin 'in the Social Stream way'
    contact = Site.current.contact_to!(self)
    contact.user_author = self
    contact.relation_ids = [ Relation::LocalAdmin.instance.id ]
    contact.save!
  end

  #Remove admin privilegies of the actor
  def degrade
    self.is_admin = false
    self.activity_object.relation_ids = [Relation::Public.instance.id]
    self.activity_object.scope = 0
    self.save!

    #Remove contact in Social Stream
    contact = Contact.where(:sender_id=>Site.current.actor.id, :receiver_id=>self.id).first
    unless contact.nil?
      contact.destroy
    end
  end

  #Return the array with the order of the categories of the user profile
  def categories_order
    order = self.category_order
    unless order.nil?
      begin
        order = JSON.parse(order).map{|pos| pos.to_i}
      rescue
        order = nil
      end
    end
    order
  end

end
