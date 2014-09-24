class WorkshopActivity < ActiveRecord::Base
	belongs_to :workshop
	has_one :wa_assignment
	has_one :wa_contributions_carousel
	has_one :wa_carousel
	has_one :wa_resource

end
