class ServiceRequest < ActiveRecord::Base
  belongs_to :actor, foreign_key: "owner_id", class_name: "Actor"

  has_attached_file :attachment
  validates_attachment_size :attachment, :in => 0.megabytes..8.megabytes, :message => 'Attachment file size is too big'

  validates :owner_id, :presence => true
  validates :status, :presence => true

  #TODO: validate duplicates
end