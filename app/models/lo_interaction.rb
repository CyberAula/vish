class LoInteraction < ActiveRecord::Base

  belongs_to :activity_object

  validates :activity_object_id, :presence => true
  validates :nsamples, :presence => true, :numericality => { :greater_than => 0 }
  validates :tlo, :presence => true, :numericality => { :greater_than => 0 }
  validates :nclicks, :presence => true, :numericality => true
  validates :acceptancerate, :presence => true, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100 }
  before_save :fill_scores_and_vars

  # Class methods

  def self.isValidTSEntry?(tsentry)
    isValidInteraction?(JSON(tsentry["data"])) rescue false
  end

  def self.isSignificativeTSEntry?(tsentry)
    isSignificativeInteraction?(JSON(tsentry["data"])) rescue false
  end

  def self.isValidInteraction?(tsdata)
    return false if tsdata.blank? or tsdata["chronology"].blank? or tsdata["duration"].blank? or tsdata["lo"].blank? or tsdata["lo"]["content"].blank? or tsdata["lo"]["content"]["slides"].blank?
    tlo = tsdata["duration"].to_i
    return false if ((tlo < 3) || (tlo > (3*60*60)))
    return true
  end

  def self.isSignificativeInteraction?(tsdata)
    tlo = tsdata["duration"].to_i
    return false if tlo < 30
    nActions = tsdata["chronology"].values.map{|v| v["actions"]}.compact.map{|v| v.values}.flatten.length
    nSlides = tsdata["lo"]["content"]["slides"].values.length
    return false if nActions < 1
    return false if nSlides > 1 and nActions < 2
    return true
  end

  # Public methods
  def extended_attributes
    attrs = {}
    attrs["nsamples"] = self.nsamples unless self.nsamples.blank?
    attrs["interactions"] = {}
    attrs["interactions"]["tlo"] = {"average_value" => self.tlo} unless self.tlo.blank?
    attrs["interactions"]["permanency_rate"] = {"average_value" => self.acceptancerate} unless self.acceptancerate.blank?
    attrs["interactions"]["nclicks"] = {"average_value" => self.nclicks/100.to_f} unless self.nclicks.blank?
    attrs
  end
  
  

  # Private methods
  private

  def fill_scores_and_vars
    tlo_weight = 0.303
    acceptance_weight = 0.435
    cpm_weight = 0.262

    tlo_threshold = 504
    acceptance_threshold = 72
    cpm_threshold = 3.6
    
    tlo_score = (self.tlo/tlo_threshold.to_f)
    acceptance_score = (self.acceptancerate/acceptance_threshold.to_f)
    cpm_score = 0
    if self.tlo > 0 and self.nclicks > 0
      cpm_score = ((self.nclicks/(self.tlo/60.to_f))/(cpm_threshold*100).to_f)
    end
    
    self.x1n = [tlo_score,1].min
    self.x2n = [acceptance_score,1].min
    self.x3n = [cpm_score,1].min

    self.interaction_qscore = 10 * (self.x1n * tlo_weight + self.x2n * acceptance_weight + self.x3n * cpm_weight)
    #Translate it to a scale of [0,1000000]
    self.qscore = [self.interaction_qscore * 100000, 999999].min
  end

end