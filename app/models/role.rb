class Role < ActiveRecord::Base
  
  has_and_belongs_to_many :actors

  validates :name,
  :allow_nil => false,
  :length => { :in => 1..255 },
  :uniqueness => {
    :case_sensitive => false
  }

  def self.default
    Role.find_by_name("User")
  end

  def self.Admin
    Role.find_by_name("Admin")
  end

  def readable_name
    I18n.t("role."+self.name.underscore, :default => self.name) unless self.name.nil?
  end

end