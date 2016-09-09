class ContestEnrollment < ActiveRecord::Base
  belongs_to :contest
  belongs_to :actor

  validates_presence_of :contest_id, allow_blank: false
  validates_presence_of :actor_id, allow_blank: false
  validate :actor_is_not_duplicated
  def actor_is_not_duplicated
    if self.contest and self.contest.contest_enrollments.map{|ce| ce.actor}.include? self.actor
      errors.add(:contest_enrollment, "actor duplicated")
    else
      true
    end
  end

  after_destroy :destroy_contest_submissions


  private

  def destroy_contest_submissions
    unless self.contest.nil?
      self.contest.submissions.select{|s| s.actor_id == self.actor.id}.each do |s|
        s.destroy
      end
    end
  end

end