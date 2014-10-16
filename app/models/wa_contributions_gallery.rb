class WaContributionsGallery < ActiveRecord::Base
	#Polymorphic
	acts_as_wa
	
	has_and_belongs_to_many :wa_assignment
	has_many :contributions, :through => :wa_assignment
end
