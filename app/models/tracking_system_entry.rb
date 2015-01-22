class TrackingSystemEntry < ActiveRecord::Base

  belongs_to :tracking_system_entry
  has_many :tracking_system_entries

  validates :app_id,
  :presence => true

  validates :data,
  :presence => true

  def self.isBoot(request)
    user_agent = request.user_agent.downcase
    return [ 'msnbot', 'yahoo! slurp','googlebot' ].detect { |bot| user_agent.include? bot }
  end

  def self.trackUIRecommendations(options,request,current_subject)
    return if options.blank? or !options[:recEngine].is_a? String
    return if isBoot(request)

    tsentry = TrackingSystemEntry.new
    tsentry.app_id = "ViSHUIRecommenderSystem"
    data = {}
    data["rsEngine"] = options[:recEngine]
    data["models"] = options[:model_names]
    data["quantity"] = options[:n]
    data["current_subject"] = (current_subject.nil? ? "anonymous" : current_subject.name)
    data["referrer"] = request.referrer
    data["user_agent"] = request.user_agent
    tsentry.data = data.to_json
    tsentry.save
  end

  def self.trackRLOsInExcursions(rec,excursion,request,current_subject)
    return if request.format == "full"
    return if isBoot(request)

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
    data = {}
    data["rec"] = rec
    data["rsEngine"] = rsEngine
    data["excursionId"] = excursion.id
    data["qscore"] = excursion.qscore
    data["popularity"] = excursion.popularity
    data["current_subject"] = (current_subject.nil? ? "anonymous" : current_subject.name)
    data["referrer"] = request.referrer
    data["user_agent"] = request.user_agent
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