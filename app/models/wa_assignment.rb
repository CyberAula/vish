class WaAssignment < ActiveRecord::Base
  #Polymorphic
  acts_as_wa

  has_many :contributions
  has_and_belongs_to_many :wa_contributions_galleries

  after_destroy :destroy_contributions

  #Save available_contributions as array
  serialize :available_contributions

  validate :has_available_contributions
  def has_available_contributions
    all_available_contributions = VishConfig.getAvailableContributionTypes()
    if self.available_contributions.nil? or (self.available_contributions_array & all_available_contributions).blank?
      errors[:base] << I18n.t("validation.invalid_available_contributions")
    else
      true
    end
  end


  #Methods

  def available_contributions_array
    self.available_contributions.split(",") unless self.available_contributions.nil?
  end


  private

  def destroy_contributions
    self.contributions.each do |contribution|
      contribution.destroy
    end
  end
  
end
