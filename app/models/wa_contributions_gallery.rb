class WaContributionsGallery < ActiveRecord::Base
  #Polymorphic
  acts_as_wa

  has_and_belongs_to_many :wa_assignments
  has_many :contributions, :through => :wa_assignments

  validate :has_wa_assignments
  def has_wa_assignments
    if self.wa_assignments.blank?
      errors[:base] << I18n.t("validation.invalid_contributions_gallery")
    else
      true
    end
  end
end
