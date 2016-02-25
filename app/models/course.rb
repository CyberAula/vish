class Course < ActiveRecord::Base
  include SocialStream::Models::Object
  has_and_belongs_to_many :users
  has_attached_file :attachment,
                    :url => '/courses/:id/attachment',                    
                    :path => ':rails_root/documents/:class/attachments/:id_partition/:filename.:extension'

  def thumbnail_url
    self.getAvatarUrl || "/assets/logos/original/default_course.png"
  end
  
end