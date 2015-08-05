class ServicePermission < ActiveRecord::Base
  belongs_to :owner, class_name: "Actor"

  validates :key, :presence => true
  validates :owner_id, :presence => true

  #TODO: validate duplicates
   

  #returns an array with all the permissions 
  def self.all_keys
  	["PrivateStudentGroups"]
  end
end