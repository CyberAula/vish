class TrackingSystemEntry < ActiveRecord::Base
  belongs_to :tracking_system_entry
  has_many :tracking_system_entries

  validates :app_id, :presence => true
  validates :data, :presence => true
  validate :valid_user_agent
  def valid_user_agent
    if TrackingSystemEntry.isUserAgentBot?(self.user_agent)
      errors[:base] << "Invalid user agent"
    else
      true
    end
  end

  def self.isBot?(request)
    return isUserAgentBot?(request.env["HTTP_USER_AGENT"])
  end

  def self.isUserAgentBot?(user_agent)
    matches = nil
    unless user_agent.blank?
      matches = user_agent.match(/(BingPreview|eSobiSubscriber|startmebot|Mail.RU_Bot|SeznamBot|360Spider|bingbot|MJ12bot|web spider|YandexBot|Baiduspider|AhrefsBot|OrangeBot|msnbot|spbot|facebook|postrank|voyager|twitterbot|googlebot|slurp|butterfly|pycurl|tweetmemebot|metauri|evrinid|reddit|digg)/mi)
    end
    return (user_agent.blank? or !matches.nil?)
  end

end