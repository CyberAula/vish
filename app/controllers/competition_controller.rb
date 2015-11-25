class CompetitionController < ApplicationController
	before_filter :authenticate_user!, :except => [:index, :all_items]

	def index
	end

	def all_items
		per_page = 25		
		params[:page]= params[:page] ? params[:page] : 1

		@competition_items = ActivityObject.where(:competition => true).page(params[:page]).per(per_page)
		respond_to do |format|
      format.html{  
        if request.xhr?
					render :partial => "all_items", :layout => false
        else
        	render 
        end        
      }
    end
	end

	def join_competition
		actor = @current_user.actor
		data = /(?<type>excursion|workshop)-(?<id>\d+)/.match(params["id"])
		resource_type = data["type"]
		resource_id = data["id"]

		if  resource_type == "excursion"
			resource = Excursion.find(resource_id)
		elsif resource_type == "workshop"
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
