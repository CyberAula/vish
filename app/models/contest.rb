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
      raise "invalid settings" if pSettings["submission"] and !["free","one_per_user","one_per_user_category"].include? pSettings["submission"]
      raise "invalid settings" if pSettings["submission_require_enroll"] and !["true","false"].include? pSettings["submission_require_enroll"]
      true
    rescue
      errors.add(:contest, "not valid settings")
    end
  end

  before_save :fill_settings
  after_destroy :destroy_contest_dependencies

  def public_submissions
    self.submissions.where("scope=0")
  end

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

  def allowEnrollments?
    ["open"].include? self.status and getParsedSettings["enroll"]==="true"
  end

  def allowSubmissions?(actor)
    return false unless actor.is_a? Actor
    return false unless ["open"].include? self.status
    settings = self.getParsedSettings
    return false if settings["submission_require_enroll"]==="true" and !self.isEnrolled?(actor)
    true
  end

  def allowMoreSubmissions?(actor)
    return false unless self.allowSubmissions?(actor)

    settings = self.getParsedSettings
    case settings["submission"]
    when "free"
    when "one_per_user"
      return false if (self.submissions.map{|ao| ao.author}.include? actor)
    when "one_per_user_category"
      return false if (self.submissions.map{|ao| ao.author}.include? actor)
    end

    true
  end

  def isEnrolled?(actor)
    self.enrolled_participants.include? actor
  end

  def hasSubmissions?(actor)
    self.participants.include? actor
  end

  def default_settings
    #Contest settings
    #enroll => true/false
    #submission =>  "free" / "one_per_user" / "one_per_user_category"
    #"submission_require_enroll" => true/false
    {"enroll" => "false", "submission" => "one_per_user", "submission_require_enroll" => "false"}
  end

  def enrollActor(actor)
    return nil unless self.allowEnrollments?
    if !actor.nil? and actor.class.name=="Actor" and !self.enrolled_participants.include? actor and ["User"].include? actor.subject_type
      self.enrolled_participants << actor
      return actor
    end
    nil
  end

  def disenrollActor(actor)
    return nil unless self.allowEnrollments?
    if !actor.nil? and self.enrolled_participants.include? actor
      self.enrolled_participants.delete(actor)
      self.categories.each do |contest_category|
        contest_category.submissions.select{|ao| ao.owner_id == actor.id}.each do |ao|
          contest_category.deleteActivityObject(ao)
        end
      end
    end
  end


  def getUrlWithName
    "/contest/" + self.name
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