class WaAssignment < ActiveRecord::Base
	has_one :workshop_activity, as: :wa_activity 
	has_many :contributions
	has_and_belongs_to_many :wa_contributions_gallery

end
