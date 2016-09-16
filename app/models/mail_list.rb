class MailList < ActiveRecord::Base
  has_one :contest
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
    self.items.map{|i| 
      c = {:mail => i.email}
      c[:name] = i.name unless i.name.blank?
      c
    }
  end

  def emails
    self.items.map{|i| i.email}
  end

  def isActorSubscribed?(actor)
    return false unless actor.is_a? Actor
    isActorSubscribed = !self.items.find_by_actor_id(actor.id).nil?
    return true if isActorSubscribed
    self.isEmailSubscribed?(actor.email)
  end

  def isEmailSubscribed?(email)
    !self.items.find_by_email(email).nil?
  end

  def subscribe_actor(actor)
    return nil unless actor.is_a? Actor
    mi = MailListItem.new
    mi.mail_list_id = self.id
    mi.actor_id = actor.id
    mi.valid?
    unless mi.errors.blank? and mi.save
      #Humanize some error messages
      if !mi.errors.messages[:email].blank? and mi.errors.messages[:email].to_sentence.include?("already subscribed")
        return I18n.t("mail_list.email_duplicated")
      end
      if !mi.errors.messages[:actor].blank? and mi.errors.messages[:actor].to_sentence.include?("already subscribed")
        return I18n.t("mail_list.actor_duplicated")
      end
      return mi.errors.full_messages.to_sentence
    end
    mi
  end

  def subscribe_email(email,name=nil)
    return I18n.t("mail_list.email_missed") if (email.blank? or !(email.is_a? String))
    mi = MailListItem.new
    mi.mail_list_id = self.id
    mi.email = email
    mi.name = name unless name.blank?
    mi.valid?
    unless mi.errors.blank? and mi.save
      #Humanize some error messages
      if !mi.errors.messages[:email].blank? and mi.errors.messages[:email].to_sentence.include?("already subscribed")
        return I18n.t("mail_list.email_duplicated")
      end
      if !mi.errors.messages[:actor].blank? and mi.errors.messages[:actor].to_sentence.include?("already subscribed")
        return I18n.t("mail_list.actor_duplicated")
      end
      return mi.errors.full_messages.to_sentence
    end
    mi
  end

  def unsubscribe_actor(actor)
    return "Actor missed" unless actor.is_a? Actor
    mis = ([self.items.find_by_id(actor.id)] + [self.items.find_by_email(actor.email)]).compact.uniq
    return nil if mis.blank?
    result = nil
    mis.each do |mi|
      result = mi.destroy
    end
    result
  end

  def unsubscribe_email(email)
    return I18n.t("mail_list.email_missed") if (email.blank? or !(email.is_a? String))
    mi = self.items.find_by_email(email)
    return nil if mi.blank?
    mi.destroy
  end

  def default_settings
    #MailList settings
    {"require_login" => "false", "require_name" => "false"}
  end
 

  private

  def fill_settings
    self.settings = (default_settings.merge(JSON.parse(self.settings))).to_json
  end

end