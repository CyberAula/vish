class License < ActiveRecord::Base
  has_many :activity_objects

  validates :key, :presence => true, :uniqueness => true


  ###########
  # Methods
  ###########

  def self.default
    License.find_by_key("cc-by-nc")
  end

  def public?
    !self.private?
  end

  def private?
    self.key === "private"
  end

  def requires_attribution?
    return self.key.include? "cc-by"
  end

  def name
    I18n.t('licenses.' + self.key.to_s)
  end

end