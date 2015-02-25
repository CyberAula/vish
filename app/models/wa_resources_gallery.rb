class WaResourcesGallery < ActiveRecord::Base
  #Polymorphic
  acts_as_wa

  has_and_belongs_to_many :activity_objects

  validate :valid_activity_objects
  def valid_activity_objects
    valid = true

    availableResources = VishConfig.getAvailableResourceModels
    self.activity_objects.each do |ao|
      unless availableResources.include? ao.object_type
        valid = false
      end
    end

    unless valid
      errors[:base] << I18n.t("validation.invalid_resources_gallery")
    else
      true
    end
  end
end
