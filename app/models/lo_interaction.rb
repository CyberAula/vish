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

    nActions = tsdata["chronology"].values.map{|v| v["actions"]}.compact.map{|v| v.values}.flatten.length
    nSlides = tsdata["lo"]["content"]["slides"].values.length

    if nActions < 1
      return false
    end

    if nSlides > 1 and nActions < 2
      return false
    end

    return true
  end

  def qscore
    tlo_weight = 0.3
    cpm_weight = 0.3
    acceptance_weight = 0.4

    tlo_threshold = 524
    cpm_threshold = 3.7
    acceptance_threshold = 73.2

    tlo_score = (self.tlo/tlo_threshold.to_f)
    cpm_score = 0
    if tlo_score > 0
      cpm_score = ((self.nclicks/(self.tlo/60.to_f))/(cpm_threshold*100).to_f)
    end
    acceptance_score = (self.acceptancerate/acceptance_threshold.to_f)

    return 10 * ([tlo_score,1].min * tlo_weight + [cpm_score,1].min * cpm_weight + [acceptance_score,1].min * acceptance_weight)
  end

end