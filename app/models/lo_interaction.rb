class LoInteraction < ActiveRecord::Base

  belongs_to :activity_object

  validates :activity_object_id, :presence => true
  validates :nsamples, :presence => true, :numericality => { :greater_than => 0 }
  validates :tlo, :presence => true, :numericality => { :greater_than => 0 }
  validates :nclicks, :presence => true, :numericality => true
  validates :acceptancerate, :presence => true, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100 }

  # Class methods

  def self.isValidTSEntry?(tsentry)
    isValidInteraction?(JSON(tsentry.data)) rescue false
  end

  def self.isValidInteraction?(tsdata)
    return false if tsdata.blank? or tsdata["chronology"].blank? or tsdata["duration"].blank? or tsdata["lo"].blank? or tsdata["lo"]["content"].blank? or tsdata["lo"]["content"]["slides"].blank?
    tlo = tsdata["duration"].to_i
    return false if ((tlo < 3) || (tlo > (3*60*60)))
    return true
  end

  def self.isValidCheckedTSEntry?(tsentry)
    isValidCheckedInteraction?(JSON(tsentry.data)) rescue false
  end

  def self.isValidCheckedInteraction?(tsdata)
    return false if tsdata.blank? or tsdata["chronology"].blank? or tsdata["duration"].blank? or tsdata["lo"].blank? or tsdata["lo"]["nSlides"].blank?
    tlo = tsdata["duration"].to_i
    return false if ((tlo < 3) || (tlo > (3*60*60)))
    return true
  end

  def self.isSignificativeCheckedTSEntry?(tsentry)
    isSignificativeCheckedInteraction?(JSON(tsentry.data)) rescue false
  end

  def self.isSignificativeCheckedInteraction?(tsdata)
    tlo = tsdata["duration"].to_i
    return false if tlo < 30
    nActions = tsdata["chronology"].values.map{|v| v["actions"]}.compact.map{|v| v.values}.flatten.length
    nSlides = tsdata["lo"]["nSlides"]
    return false if nActions < 1
    return false if nSlides > 1 and nActions < 2
    return true
  end

  # Public methods
  def extended_attributes
    attrs = {}
    attrs["nsamples"] = self.nvalidsamples unless self.nvalidsamples.blank?
    attrs["nsignificativesamples"] = self.nsamples unless self.nsamples.blank?
    attrs["interactions"] = {}
    attrs["interactions"]["tlo"] = {"average_value" => self.tlo} unless self.tlo.blank?
    attrs["interactions"]["permanency_rate"] = {"average_value" => self.acceptancerate} unless self.acceptancerate.blank?
    attrs["interactions"]["nclicks"] = {"average_value" => self.nclicks/100.to_f} unless self.nclicks.blank?
    attrs
  end

end