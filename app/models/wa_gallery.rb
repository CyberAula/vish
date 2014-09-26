class WaGallery < ActiveRecord::Base
	has_one :workshop_activity, as: :wa_activity 	


end
