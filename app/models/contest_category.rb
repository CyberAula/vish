class ContestCategory < ActiveRecord::Base
  belongs_to :contest
  has_many :submissions, :class_name => "ContestSubmission"
  has_many :activity_objects, :through => :submissions

  validates_presence_of :contest_id, allow_blank: false
  validate :has_valid_contest
  def has_valid_contest
    if self.contest.nil?
      errors.add(:contest_category, "not valid contest")
    else
      true
    end
  end
  validates_presence_of :name, allow_blank: false
  validate :name_is_not_duplicated
  def name_is_not_duplicated
    if self.contest and self.contest.categories.map{|c| c.name}.include? self.name
      errors.add(:contest_category, "name duplicated")
    else
      true
    end
  end

  after_destroy :destroy_contest_category_dependencies

  def addActivityObject(ao)
    return I18n.t("contest.submissions.not_valid") unless !ao.nil? and ao.class.name=="ActivityObject" and ao.scope==0
    return I18n.t("contribution.messages.duplicated") if self.activity_objects.include? ao
    cs = ContestSubmission.new
    cs.contest_category_id = self.id
    cs.activity_object_id = ao.id
    cs.actor_id = ao.owner_id
    cs.valid?
    return cs.errors.full_messages.to_sentence unless cs.errors.blank? and cs.save
    cs.activity_object
  end

  def deleteActivityObject(ao)
    return "Resource is not valid" if ao.nil?
    cs = self.submissions.find{|s| s.activity_object == ao}
    return "Resource not found" if cs.nil?
    cs.destroy
    cs.activity_object
  end

  def participants
    self.activity_objects.map{|s| s.owner}
  end


  private

  def destroy_contest_category_dependencies
    self.submissions.each do |s|
      s.destroy
    end
  end

end