class Course < ActiveRecord::Base
  include SocialStream::Models::Object
  has_and_belongs_to_many :users
  has_attached_file :attachment,
                    :url => '/courses/:id/attachment',
                    :path => ':rails_root/documents/:class/attachments/:id_partition/:filename.:extension'
  after_save :update_course_count

  def thumbnail_url
    self.getAvatarUrl || "/assets/logos/original/default_course.png"
  end

  def has_password?
    restriction_password.present?
  end


  private

  def update_course_count
    Vish::Application.config.courses_count = Course.count
  end
end
