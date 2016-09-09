class ContestSubmission < ActiveRecord::Base
  belongs_to :contest_category
  belongs_to :activity_object
  belongs_to :actor

  validates_presence_of :contest_category_id, allow_blank: false
  validates_presence_of :activity_object_id, allow_blank: false
  validates_presence_of :actor_id, allow_blank: false
  validate :has_valid_contest_category
  def has_valid_contest_category
    if self.contest_category.nil?
      errors.add(:contest_submission, "not valid contest category")
    else
      true
    end
  end
  validate :has_valid_ao
  def has_valid_ao
    if self.actor.nil? or self.activity_object.nil? or self.actor_id != self.activity_object.owner_id
      errors.add(:contest_submission, "not valid activity object and/or actor")
    elsif self.contest_category.activity_objects.include? self.activity_object
      errors.add(:contest_submission, "duplicated activity_object")
    elsif self.activity_object.private_scope?
      errors.add(:contest_submission, "activity_object not public")
    else
      true
    end
  end


  before_save :fill_actor

  private

  def fill_actor
    self.actor_id = self.activity_object.owner_id if self.actor.nil? and !self.activity_object.nil?
  end

end