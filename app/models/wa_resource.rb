class WaResource < ActiveRecord::Base
	#Polymorphic
	acts_as_wa
	
	belongs_to :activity_object

	validates_presence_of :activity_object_id

end
