class WaResource < ActiveRecord::Base
  #Polymorphic
  acts_as_wa

  belongs_to :activity_object

  validates_presence_of :activity_object_id

  validate :valid_activity_object
  def valid_activity_object
    if self.activity_object.nil? or !VishConfig.getAvailableResourceModels.reject{|rmodel| ["Workshop"].include? rmodel}.include? self.activity_object.object_type or !self.activity_object.public?
      errors[:base] << I18n.t("validation.invalid_resource")
    end
  end

end
