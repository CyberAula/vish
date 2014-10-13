class WorkshopActivity < ActiveRecord::Base
	belongs_to :workshop
	belongs_to :wa_activity, polymorphic: true
end
