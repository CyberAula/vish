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

  def custom?
    self.key === "other"
  end

  def requires_attribution?
    return (self.key.include? "cc-by" or self.custom?)
  end

  def shared_alike?
    return (self.key.include? "cc-by" and self.key.include? "-sa")
  end

  def no_derivatives?
    return (self.key.include? "cc-by" and self.key.include? "-nd")
  end

  def name(locale=nil)
    options = {}
    options[:locale] = locale unless locale.nil? or !I18n.available_locales.include?(locale.to_sym)
    I18n.t('licenses.' + self.key.to_s, options)
  end

end