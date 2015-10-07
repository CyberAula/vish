class CompetitionController < ApplicationController
	before_filter :authenticate_user!, :except => [:index]

	def index
	end

	def join 
	end

	def join_competition
		actor = params[:id]
		resource = ActivityObject.find(params[:resource_subscription])
		if is_item_allowed(resource)

		end
	end

private
	def is_item_allowed(item)
		true	
	end
end


