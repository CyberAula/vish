class WaContributionsGallery < ActiveRecord::Base
  #Polymorphic
  acts_as_wa

  has_and_belongs_to_many :wa_assignments
  has_many :contributions, :through => :wa_assignments

  validate :has_wa_assignments
  def has_wa_assignments
    if self.wa_assignments.blank?
      errors.add(:contributions_gallery, I18n.t('workshop.activities.contributions_gallery.error'))
    else
      true
    end
  end
end
