class Category < ActiveRecord::Base
  include SocialStream::Models::Object

  #Parent
  belongs_to :parent, :class_name => 'Category', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Category', :foreign_key => 'parent_id'

  validates_presence_of :title
  validate :title_not_duplicated
  validate :has_valid_title_length
  validate :has_valid_parent
  
  def title_not_duplicated
    if self.isRoot?
      owner = Actor.find_by_id(self.owner_id)
      return false if owner.nil?
      categories = Category.authored_by(owner).select{|c| c.isRoot?}
    else
      categories = self.parent.children
    end
    categories = categories.reject{|c| c==self}

    if categories.select{|c| c.title==self.title}.length > 0
      errors[:base] << "There is another category with the same title"
    else
      true
    end
  end

  def has_valid_title_length
    if self.title.length > 50
      errors[:base] << "Title is too long."
    else
      true
    end
  end

  def has_valid_parent
    if (!self.parent_id.nil? and self.parent.nil?) or (!self.parent.nil? and (self.parent==self or self.all_category_children.include? self.parent))
      errors.add(:category, "Invalid parent")
    else
      true
    end
  end

  before_save :check_property_objects
  after_save :check_parent_property_objects
  after_destroy :remove_children

  define_index do
    activity_object_index
  end

  #Model Methods

  #Return the array with the order of the items of the category
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

  def calculate_qscore
    return if self.activity_object.nil?

    categoryResources = self.all_property_objects.select{|ao| ao.qscore.is_a? Numeric}
    if categoryResources.length < 1
      overallQualityScore = 0
    else
      overallQualityScore = categoryResources.map{|c| c.qscore}.sum/categoryResources.length
    end
    
    self.activity_object.update_column :qscore, overallQualityScore
    overallQualityScore
  end

  def isRoot?
    self.parent.nil?
  end

  def all_category_children
    all_children = []
    direct_children = children
    all_children += direct_children

    direct_children.each do |dchildren|
      all_children += dchildren.all_category_children
    end

    all_children
  end

  def all_property_objects
    all_property_objects = self.property_objects.reject{|c| c.object_type=="Category"}

    direct_children = children
    direct_children.each do |dchildren|
      all_property_objects += dchildren.all_property_objects
    end

    all_property_objects.uniq
  end

  def parents_path(path=nil)
    path ||= [self]
    cp = self.parent

    unless cp.nil?
      path.unshift(cp)
      return cp.parents_path(path)
    end

    return path
  end

  def valid_property_objects
    self.property_objects.reject{|ao| ao.object_type=="Category" and ao.object.parent_id!=self.id}.uniq
  end

  def insertPropertyObject(object)
    if !object.nil? and object.class.name=="ActivityObject" and !self.property_objects.include? object
      self.property_objects << object
    end
  end

  def deletePropertyObject(object)
    if !object.nil? and self.property_objects.include? object
      self.property_objects.delete(object)
    end
  end

  def setPropertyObjects(property_objects=nil)
    property_objects ||= self.property_objects.clone
    property_objects = property_objects.uniq
    self.property_objects = []
    self.property_objects = property_objects
  end

  def self.category_parents_options_for_select(current_subject,category=nil)
    allCategories = Category.authored_by(current_subject)
    unless category.nil?
      categoryChildren = category.all_category_children
      allCategories.reject!{|c| categoryChildren.include? c or c==category}
    end
    ([["",nil]] + allCategories.sort_by!{|e| e.title.downcase}.map{|c| [c.title, c.id]}).uniq
  end

  #SCORM
  def to_scorm(controller,folderPath,fileName,version="2004",options={})
    excursions = self.all_property_objects.select{|ao| ao.object_type=="Excursion" and ao.scope=0}.map{|ao| ao.object}
    return nil unless excursions.length > 0
    Excursion.createSCORMForGroup(version,folderPath,fileName,excursions,controller,options)
  end

  def as_json(options = nil)
    {
     :id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :url => options[:helper].polymorphic_url(self),
     :elements => property_objects.map{|ao| ao.getGlobalId },
     :type => self.class.name
    }
  end

  private

  def check_property_objects
    hasInvalidPropertyObjects = (self.property_objects != self.valid_property_objects)
    if hasInvalidPropertyObjects
      self.setPropertyObjects(self.valid_property_objects.clone)
    end
  end

  def check_parent_property_objects
    unless self.parent.nil?
      self.parent.insertPropertyObject(self.activity_object)
    end
    unless self.parent_id_was.nil?
      old_parent = Category.find_by_id(self.parent_id_was)
      unless old_parent.nil? or old_parent == self.parent
        old_parent.deletePropertyObject(self.activity_object)
      end
    end
  end

  def remove_children
    self.children.each do |children|
      children.destroy
    end
  end

end