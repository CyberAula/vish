class ServiceRequest < ActiveRecord::Base
  belongs_to :owner, class_name: "Actor"

  has_attached_file :attachment,
                    :url => '/service_requests/:id/attachment',
                    :path => ':rails_root/documents/:class/attachments/:id_partition/:filename.:extension'
  validates_attachment_size :attachment, :in => 0.megabytes..8.megabytes, :message => 'Attachment file size is too big'

  validates :owner_id, :presence => true
  validates :status, :presence => true

	#TODO: validate duplicates

  def accepted?
    self.status == "Accepted"
  end

  def pending?
    !self.accepted?
  end

  def afterAccept
    #Override this method on the specific ServiceRequest
  end


  def readable_type
    if type=="ServiceRequest::PrivateStudentGroup"
      "private_student"
    else
      "default"
    end
  end

end
