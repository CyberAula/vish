class WaContributionsGallery < ActiveRecord::Base
	has_one :workshop_activity, as: :wa_activity 
	has_and_belongs_to_many :wa_assignment
	has_many :contributions, :through => :wa_assignment

end
