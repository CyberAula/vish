class TrackingSystemEntry < ActiveRecord::Base

  belongs_to :tracking_system_entry
  has_many :tracking_system_entries

  validates :app_id,
  :presence => true

  validates :data,
  :presence => true

  validate :valid_user_agent
  def valid_user_agent
    if TrackingSystemEntry.isUserAgentBot?(self.user_agent)
      errors[:base] << "Invalid user agent"
    else
      true
    end
  end

  def self.isUserAgentBot?(user_agent)
    matches = nil
    unless user_agent.blank?
      matches = user_agent.match(/(startmebot|Mail.RU_Bot|SeznamBot|360Spider|bingbot|MJ12bot|web spider|YandexBot|Baiduspider|AhrefsBot|OrangeBot|msnbot|spbot|facebook|postrank|voyager|twitterbot|googlebot|slurp|butterfly|pycurl|tweetmemebot|metauri|evrinid|reddit|digg)/mi)
    end
    return (user_agent.blank? or !matches.nil?)
  end

  def self.isBot?(request)
    user_agent = request.env["HTTP_USER_AGENT"]
    return isUserAgentBot?(user_agent)
  end

  def self.trackUIRecommendations(options,request,current_subject)
    return if isBot?(request)
    return if options.blank? or !options[:recEngine].is_a? String
    
    tsentry = TrackingSystemEntry.new
    tsentry.app_id = "ViSHUIRecommenderSystem"
    tsentry.user_agent = request.user_agent
    tsentry.referrer = request.referrer
    tsentry.actor_id = (current_subject.nil? ? nil : Actor.normalize_id(current_subject))

    data = {}
    data["rsEngine"] = options[:recEngine]
    data["models"] = options[:model_names]
    data["quantity"] = options[:n]

    tsentry.data = data.to_json
    tsentry.save
  end

  def self.trackRLOsInExcursions(rec,excursion,request,current_subject)
    return if request.format == "full"
    return if isBot?(request)

    if rec.is_a? String
      rsEngine = getRSName(rec)
      return if rsEngine.nil?
      rec = true
    else
      rec = false
      rsEngine = "none"
    end

    tsentry = TrackingSystemEntry.new
    tsentry.app_id = "ViSH RLOsInExcursions"
    tsentry.user_agent = request.user_agent
    tsentry.referrer = request.referrer
    tsentry.actor_id = (current_subject.nil? ? nil : Actor.normalize_id(current_subject))

    data = {}
    data["rec"] = rec
    data["rsEngine"] = rsEngine
    data["excursionId"] = excursion.id
    data["qscore"] = excursion.qscore
    data["popularity"] = excursion.popularity
    tsentry.data = data.to_json

    if tsentry.save
      tsentry
    else
      nil
    end
  end

  def self.getRandomRSEngine
    return (rand < 0.5 ? "ViSHRecommenderSystem" : "ViSHRS-Quality")
  end

  def self.getRSCode(str)
    case str
    when "Random"
      "0"
    when "ViSHRecommenderSystem"
       "1"
     when "ViSHRS-Quality"
       "2"
    when "ViSHRS-Quality-Popularity"
      "3"
    else
      nil
    end
  end

  def self.getRSName(str)
    case str
    when "0"
      "Random"
    when "1"
      "ViSHRecommenderSystem"
    when "2"
      "ViSHRS-Quality"
    when "3"
      "ViSHRS-Quality-Popularity"
    else
      nil
    end
  end

end