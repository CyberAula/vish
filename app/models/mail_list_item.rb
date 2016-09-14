class MailListItem < ActiveRecord::Base
  belongs_to :mail_list

  validates :mail_list_id, :presence => true, :allow_blank => false
  validates :email, :presence => true, :allow_blank => false, :uniqueness => {:scope => :mail_list_id}

  validate :valid_mail_list_and_name
  def valid_mail_list_and_name
    if self.mail_list.nil?
      errors[:base] << "MailList not found"
      return false
    end
    
    settings = self.mail_list.getParsedSettings

    if settings["require_name"] == "true"
      #Validate name
      return (errors[:base] << "Blank name not allowed for this MailList in MailListItem") if self.name.blank?
    end

    true
  end

  validate :valid_email
  def valid_email
    valid_email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    unless self.email and !((self.email =~ valid_email_regex).nil?)
      return (errors[:base] << "Email is not valid")
    end
    true
  end
  
end