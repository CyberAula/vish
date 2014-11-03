class WaAssignment < ActiveRecord::Base
  #Polymorphic
  acts_as_wa

  has_many :contributions
  has_and_belongs_to_many :wa_contributions_gallery

  #Save available_contributions as array
  serialize   :available_contributions

  validate :has_available_contributions
  def has_available_contributions
    all_available_contributions = ["document","writing","excursion","link"]
    if self.available_contributions.nil? or (self.available_contributions_array & all_available_contributions).blank?
      errors.add(:contribution, "Invalid available contributions")
    else
      true
    end
  end


  #Methods

  def available_contributions_array
    self.available_contributions.split(",") unless self.available_contributions.nil?
  end
  
end
