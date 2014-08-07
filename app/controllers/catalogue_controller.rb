class CatalogueController < ApplicationController

	def index
		@default_categories = Hash.new
		for category in Vish::Application.config.default_categories
			@default_categories[category] = getCategoryResources(category,7)
		end

		respond_to do |format|			
      		format.html { 
      			if request.xhr?
      				  if params[:category] 
		                @excursions = getCategoryResources(params[:category])
		                render :partial => 'catalogue/show'
		              else               
		                render :partial => "catalogue/index", :locals =>{ :is_home=> params[:is_home]}
		              end
      			else
      				render :layout => 'catalogue' 
      			end
      		}    		
    	end
	end

	def show
		@category = params[:category]
		@excursions = getCategoryResources(@category)		
		respond_to do |format|
			format.all { render :layout => 'catalogue' }    		
    	end
	end


	private

	def getCategoryResources(category,limit=100)
		keywords = Vish::Application.config.catalogue[category]
		RecommenderSystem.search({:keywords=>keywords, :n=>limit, :models => [Excursion], :order => 'ranking DESC', :qualityThreshold=>5})
	end

end
