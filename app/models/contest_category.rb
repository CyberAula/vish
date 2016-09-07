class ContestCategory < ActiveRecord::Base
  belongs_to :contest
  has_and_belongs_to_many :submissions, :class_name => "ActivityObject"

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

  before_save :check_submissions

  def insertActivityObject(ao)
    return I18n.t("contest.submissions.not_valid") unless !ao.nil? and ao.class.name=="ActivityObject" and ao.scope==0
    return I18n.t("contribution.messages.duplicated") if self.submissions.include? ao
    self.submissions << ao
    ao
  end

  def insertActivityObjects(aos)
    aos.each do |ao|
      self.insertActivityObject(ao)
    end
  end

  def deleteActivityObject(ao)
    return "Resource is not valid" if ao.nil?
    return "Resource not found" unless self.submissions.include? ao
    self.submissions.delete(ao)
  end

  def setActivityObjects(aos=nil)
    aos ||= self.submissions.clone
    aos = aos.uniq
    self.submissions = []
    insertActivityObjects(aos)
  end

  def updateActivityObjects
    setActivityObjects
  end


  private

  def check_submissions
    vaos = self.submissions.select{|ao| ao.scope==0}.uniq
    self.setActivityObjects(vaos.clone) if (self.submissions != vaos)
  end

end