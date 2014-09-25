class WaContributionsGallery < ActiveRecord::Base
	belongs_to :workshop_activity
	has_and_belongs_to_many :wa_assignment
	has_many :contributions, :through => :wa_assignment

end
