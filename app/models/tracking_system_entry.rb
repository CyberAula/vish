class TrackingSystemEntry < ActiveRecord::Base

  validates :app_id,
  :presence => true

  validates :data,
  :presence => true

  def self.trackRLOsInExcursions(rec,excursion,request,current_subject)
    return if request.format == "full"

    if rec=="true"
      rec = true
    else
      rec = false
    end

    tsentry = TrackingSystemEntry.new
    tsentry.app_id = "ViSH RLOsInExcursions"
    data = {}
    data["rec"] = rec
    data["referrer"] = request.referrer
    data["excursionId"] = excursion.id
    data["current_subject"] = (current_subject.nil? ? "anonymous" : current_subject.name)
    tsentry.data = data.to_json
    tsentry.save
  end

end