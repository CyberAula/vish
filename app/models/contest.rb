class Contest < ActiveRecord::Base
  has_and_belongs_to_many :enrolled_participants, :class_name => "Actor"
  has_many :categories, :class_name => "ContestCategory"
  has_many :submissions, :through => :categories

  validates :name, :presence => true, :allow_blank => false, :uniqueness => true
  validates_presence_of :template, allow_blank: false
  validates_inclusion_of :status, :in => ["open", "closed"]

  validate :valid_settings
  def valid_settings
    begin
      pSettings = JSON.parse(self.settings)
      raise "invalid settings" if pSettings["enroll"] and !["true","false"].include? pSettings["enroll"]
      raise "invalid settings" if pSettings["submission"] and !["free","one_per_author","one_per_author_category"].include? pSettings["submission"]
      raise "invalid settings" if pSettings["submission_require_enroll"] and !["true","false"].include? pSettings["submission_require_enroll"]
      true
    rescue
      errors.add(:contest, "not valid settings")
    end
  end

  before_save :fill_settings
  after_destroy :destroy_contest_dependencies

  def participants
    self.submissions.map{|s| s.author}
  end

  def all_participants
    (self.enrolled_participants + self.participants).uniq
  end

  def getParsedSettings
    parsedSettings = JSON.parse(self.settings) rescue {}
    default_settings.merge(parsedSettings)
  end

  def default_settings
    #Contest settings
    #enroll => true/false
    #submission =>  "free" / "one_per_author" / "one_per_author_category"
    #"submission_require_enroll" => true/false
    {"enroll" => "false", "submission" => "one_per_author", "submission_require_enroll" => "false"}
  end

  def enrollActor(actor)
    if !actor.nil? and actor.class.name=="Actor" and !self.enrolled_participants.include? actor and ["User"].include? actor.subject_type
      self.enrolled_participants << actor
      return actor
    end
    nil
  end

  def disenrollActor(actor)
    self.enrolled_participants.delete(actor) if !actor.nil? and self.enrolled_participants.include? actor
  end


  private

  def fill_settings
    self.settings = (default_settings.merge(JSON.parse(self.settings))).to_json
  end

  def destroy_contest_dependencies
    self.categories.each do |contest_category|
      contest_category.destroy
    end
  end
end