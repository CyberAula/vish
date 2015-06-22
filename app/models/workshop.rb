require 'builder'

class Workshop < ActiveRecord::Base
  include SocialStream::Models::Object
  has_many :workshop_activities

  after_destroy :destroy_workshop_activities

  define_index do
    activity_object_index
    has draft
  end

  validates_inclusion_of :draft, :in => [true, false]

  def thumbnail_url
    self.getAvatarUrl || "/assets/logos/original/defaul_workshop.png"
  end

  def hasAssignments
    self.workshop_activities.select{|workshop_activity| workshop_activity.wa_type=="WaAssignment"}.length > 0
  end

  def contributions
    self.workshop_activities.select{|workshop_activity| workshop_activity.wa_type=="WaAssignment"}.map{|workshop_activity| workshop_activity.object.contributions}.flatten.uniq
  end


  private

  def destroy_workshop_activities
    self.workshop_activities.each do |wactivity|
      wactivity.destroy
    end
  end

end
