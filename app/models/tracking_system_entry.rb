class TrackingSystemEntry < ActiveRecord::Base

  belongs_to :tracking_system_entry
  has_many :tracking_system_entries

  validates :app_id,
  :presence => true

  validates :data,
  :presence => true

  def tre
    self.trancking_system_entries.first
  end

  def self.trackUIRecommendations(options)
    return if options.blank? or !options[:recEngine].is_a? String
    tsentry = TrackingSystemEntry.new
    tsentry.app_id = "ViSHUIRecommenderSystem"
    data = {}
    data["rsEngine"] = options[:recEngine]
    data["models"] = options[:model_names]
    data["quantity"] = options[:n]
    tsentry.data = data.to_json
    tsentry.save
  end

  def self.trackRLOsInExcursions(rec,excursion,request,current_subject)
    return if request.format == "full"

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
    data["referrer"] = request.referrer
    data["excursionId"] = excursion.id
    data["qscore"] = excursion.qscore
    data["popularity"] = excursion.popularity
    data["current_subject"] = (current_subject.nil? ? "anonymous" : current_subject.name)
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