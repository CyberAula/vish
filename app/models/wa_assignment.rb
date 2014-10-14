class WaAssignment < ActiveRecord::Base
	#Polymorphic
	acts_as_wa

	# has_many :contributions
	# has_and_belongs_to_many :wa_contributions_gallery
end
