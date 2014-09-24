class WaAssignment < ActiveRecord::Base
	belongs_to :workshop_activity
	has_many :contributions
	has_and_belongs_to_many :wa_contributions_carousel

end
