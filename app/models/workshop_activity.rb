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
