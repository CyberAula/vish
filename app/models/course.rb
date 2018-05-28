require 'csv'

class Course < ActiveRecord::Base
  include SocialStream::Models::Object
  has_and_belongs_to_many :users
  has_attached_file :attachment,
                    :url => '/courses/:id/attachment',
                    :path => ':rails_root/documents/:class/attachments/:id_partition/:filename.:extension'
  after_save :update_course_count
  before_save :curate_restriction_email_list

  define_index do
    activity_object_index
  end

  def thumbnail_url
    self.getAvatarUrl || "/assets/logos/original/default_course.png"
  end

  def has_password?
    restriction_password.present?
  end

  def can_enrol_user_with_mail mail
    if restriction_email_list.present?
      return restriction_email_list.parse_csv.include?(mail)
    else
      return true
    end
  end
  private

  def update_course_count
    Vish::Application.config.courses_count = Course.count
  end

  def curate_restriction_email_list
    if self.restricted && self.restriction_email_list.present?
      self.restriction_email_list = self.restriction_email_list.gsub("\n","").gsub("\r","").gsub(" ","").gsub("\n","").gsub("\r","").gsub(" ","")
    end
  end
end
