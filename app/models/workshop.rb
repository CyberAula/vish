class Workshop < ActiveRecord::Base
	belongs_to :activity_object
	has_many :workshop_actitities


end
