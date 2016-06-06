require 'builder'

class Workshop < ActiveRecord::Base
  include SocialStream::Models::Object
  has_many :workshop_activities

  has_attached_file :banner, styles: { large: "1280x100#" }, default_url: "/assets/logos/original/defaul_workshop_banner.png"
  validates_attachment_content_type :banner, content_type: /\Aimage\/.*\Z/
  
  after_destroy :destroy_workshop_activities

  define_index do
    activity_object_index
    has draft
  end

  validates_presence_of :title, allow_blank: false
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

  def afterPublish
    #Check if post_activity is public. If not, make it public and update the created_at param.
    post_activity = self.post_activity
    unless post_activity.nil? or post_activity.public?
      #Update the created_at param.
      post_activity.created_at = Time.now
      #Make it public
      post_activity.relation_ids = [Relation::Public.instance.id]
      post_activity.save!
    end
  end


  private

  def destroy_workshop_activities
    self.workshop_activities.each do |wactivity|
      wactivity.destroy
    end
  end

end
