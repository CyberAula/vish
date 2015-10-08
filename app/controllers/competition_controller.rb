class CompetitionController < ApplicationController
	before_filter :authenticate_user!, :except => [:index]

	def index
	end

	def join_competition
		actor = @current_user.actor
		data = /(?<type>excursion|workshop)-(?<id>\d+)/.match(params["id"])
		resource_type = data["type"]
		resource_id = data["id"]

		if  resource_type == "excursion"
			resource = Excursion.find(resource_id)
		elsif resource_type == "eorkshop"
			resource = Workshop.find(resource_id)
		else 
			resource = nil
		end
		
		if is_item_allowed(resource)
			resource.competition = true
			resource.save

			actor.joined_competition = true
			actor.save
		end

		redirect_to "/competition"
	end

private
	def is_item_allowed(item)
		if item != nil
			true
		end
	end

end


