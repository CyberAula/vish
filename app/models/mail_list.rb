class MailList < ActiveRecord::Base
  has_many :items, :class_name => "MailListItem", :dependent => :destroy

  validates :name, :presence => true, :allow_blank => false, :uniqueness => true

  validate :valid_settings
  def valid_settings
    begin
      pSettings = JSON.parse(self.settings)
      true
    rescue
      errors.add(:contest, "not valid settings")
    end
  end

  before_save :fill_settings

  def getParsedSettings
    parsedSettings = JSON.parse(self.settings) rescue {}
    default_settings.merge(parsedSettings)
  end

  def contacts
    self.items.map{|i| {:name => (i.name || "Unknown"), :mail => i.email}}
  end

  def emails
    self.items.map{|i| i.email}
  end

  def default_settings
    #MailList settings
    {"require_name" => "false"}
  end
 
  private

  def fill_settings
    self.settings = (default_settings.merge(JSON.parse(self.settings))).to_json
  end

end