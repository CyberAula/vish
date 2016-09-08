Actor.class_eval do

  has_and_belongs_to_many :roles
  has_many :private_student_groups, foreign_key: "owner_id"
  has_many :private_students, class_name: "User", through: :private_student_groups
  has_many :actor_historial, :dependent => :destroy
  has_many :past_activity_objects, through: :actor_historial, source: :activity_object
  has_one :rsevaluation
  has_many :contest_enrollments, :dependent => :destroy
  has_many :contests, :through => :contest_enrollments

  before_save :fill_roles


  #Role Management

  def role
    self.sorted_roles.first
  end

  def sorted_roles
    self.roles.sort_by{|r| r.value}.reverse
  end

  def role_name
    role.readable_name unless role.nil?
  end

  def role?(roleName)
    return !!self.roles.find_by_name(roleName.to_s.camelize)
  end

  def admin?
    role?("Admin")
  end

  #Make the actor admin
  def make_me_admin
    self.roles.push(Role.Admin) unless self.roles.include? Role.Admin
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
    self.roles.delete(Role.Admin)
    self.roles.push(Role.default) if self.roles.empty?
    self.activity_object.relation_ids = [Relation::Public.instance.id]
    self.activity_object.scope = 0
    self.save!

    #Remove contact in Social Stream
    contact = Contact.where(:sender_id=>Site.current.actor.id, :receiver_id=>self.id).first
    contact.destroy unless contact.nil?
  end


  #Other methods

  # Activities are shared publicly by default
  def activity_relations
    [ Relation::Public.instance ]
  end

  def create_slug
    return unless self.slug.nil? or !self.name.nil?
    
    my_slug = self.name.to_url
    final_slug = my_slug
    index = 0
    while(Actor.exists?(:slug => final_slug))
      index += 1
      final_slug = my_slug + index.to_s      
    end

    self.update_column :slug, final_slug

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

  def service_requests
    ServiceRequest.where(:owner_id => self.id)
  end

  def service_permissions
    ServicePermission.where(:owner_id => self.id)
  end

  def pastLOs(n=10)
    self.past_activity_objects.last(n).reverse.map{|ao| ao.object}
  end


  private

  def fill_roles
    self.roles.push(Role.default) if self.roles.empty?
  end

end
