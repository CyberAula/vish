class WorkshopActivity < ActiveRecord::Base
  #Polymorphic
  belongs_to  :wa, :polymorphic => true

  belongs_to :workshop

  before_validation :fill_position
  after_destroy :destroy_object

  validates_presence_of :position


  def object
    wa
  end

  def titleToPrint
    return self.title unless self.title.nil?
    return nil if self.object.nil?

    case self.object.class.name
    when "WaResource"
      return self.object.activity_object.title unless self.object.activity_object.nil?
      return I18n.t("workshop.activities.resource.title")
    when "WaResourcesGallery"
      return I18n.t("workshop.activities.resource_gallery.title")
    when "WaContributionsGallery"
      return I18n.t("workshop.activities.contributions_gallery.title")
    when "WaText"
      return I18n.t("workshop.activities.text.title")
    when "WaAssignment"
      return I18n.t("workshop.activities.assignment.title")
    else
    end
 
    return nil
  end


  private

  def fill_position
    if self.position.nil?
      self.position = self.workshop.workshop_activities.length + 1
    end
  end

  def destroy_object
    wa.destroy unless wa.nil?
  end

end
