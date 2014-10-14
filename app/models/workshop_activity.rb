class WorkshopActivity < ActiveRecord::Base
	#Polymorphic
	belongs_to  :wa, :polymorphic => true

	belongs_to :workshop

	def object
		wa
	end

	after_destroy :destroy_object
	def destroy_object
		wa.destroy unless wa.nil?
	end
end
