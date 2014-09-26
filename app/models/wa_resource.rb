class WaResource < ActiveRecord::Base
	has_one :workshop_activity, as: :wa_activity 
	belongs_to :activity_object
	


end
