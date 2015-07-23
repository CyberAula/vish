class ServicePermission < ActiveRecord::Base
  belongs_to :actor, foreign_key: "owner_id", class_name: "Actor"

  validates :key, :presence => true
  validates :owner_id, :presence => true

  #TODO: validate duplicates
end