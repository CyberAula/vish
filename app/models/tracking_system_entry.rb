class TrackingSystemEntry < ActiveRecord::Base

  validates :app_id,
  :presence => true

  validates :data,
  :presence => true

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
    tsentry.save
  end

  def self.getRandomRSEngine
    return (rand < 0.5 ? "ViSHRecommenderSystem" : "ViSHRS-Quality")
  end

  def self.getRSCode(str)
    case str
    when "ViSHRecommenderSystem"
       "1"
     when "ViSHRS-Quality"
       "2"
     else
      nil
    end
  end

  def self.getRSName(str)
    case str
    when "1"
      "ViSHRecommenderSystem"
    when "2"
      "ViSHRS-Quality"
    else
      nil
    end
  end

end