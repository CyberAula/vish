class MailListItem < ActiveRecord::Base
  belongs_to :mail_list
  belongs_to :actor

  before_validation :fill_from_actor

  validates :mail_list_id, :presence => true, :allow_blank => false
  validates :actor_id, :allow_blank => true, :uniqueness => {:scope => :mail_list_id, :message => "is already subscribed"}
  validates :email, :presence => true, :allow_blank => false, :uniqueness => {:scope => :mail_list_id, :message => "is already subscribed"}

  validate :valid_mail_list_and_settings
  def valid_mail_list_and_settings
    return (errors[:base] << "MailList not found") if self.mail_list.nil?
    
    settings = self.mail_list.getParsedSettings

    if settings["require_login"] == "true"
      #Validate actor
      return (errors[:base] << I18n.t("mail_list.actor_required")) unless self.actor
    end

    if settings["require_name"] == "true"
      #Validate name
      return (errors[:base] << I18n.t("mail_list.blank_name_not_allowed")) if self.name.blank?
    end

    true
  end

  validate :valid_email
  def valid_email
    valid_email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    unless self.email and !((self.email =~ valid_email_regex).nil?)
      return (errors[:base] << I18n.t("mail_list.email_not_valid"))
    end
    true
  end


  private

  def fill_from_actor
    if self.actor
      self.email = self.actor.email if self.email.blank?
      self.name = self.actor.name if self.name.blank?
    end
  end
  
end