class LoInteraction < ActiveRecord::Base

  belongs_to :activity_object

  validates :activity_object_id, :presence => true

  validates :tlo, :presence => true

  def self.isValidTSEntry?(tsentry)
    isValidInteraction?(JSON(tsentry["data"])) rescue false
  end

  def self.isSignificativeTSEntry?(tsentry)
    isSignificativeInteraction?(JSON(tsentry["data"])) rescue false
  end

  def self.isValidInteraction?(tsdata)
    if tsdata.blank? or tsdata["chronology"].blank? or tsdata["duration"].blank? or tsdata["lo"].blank? or tsdata["lo"]["content"].blank? or tsdata["lo"]["content"]["slides"].blank?
      return false
    end

    tlo = tsdata["duration"].to_i
    if (tlo < 3) || (tlo > (2*60*60))
      return false
    end

    return true
  end

  def self.isSignificativeInteraction?(tsdata)
    tlo = tsdata["duration"].to_i

    if tlo < 30
      return false
    end

    nActions = tsdata["chronology"].values.map{|v| v["actions"].values}.flatten.length
    nSlides = tsdata["lo"]["content"]["slides"].values.length

    if nActions < 1
      return false
    end

    if nSlides > 1 and nActions < 2
      return false
    end

    return true
  end

end