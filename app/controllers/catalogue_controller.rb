class CatalogueController < ApplicationController
	DEFAULT_CATEGORIES = ["physics", "chemistry", "biology", "maths"]
	LIMIT_IN_SHOW = 40 #max number of excursions shown per category


	def index
		@all_categories = Hash.new
		for cat in DEFAULT_CATEGORIES 
			@all_categories[cat] = search(cat, 7)
		end

		respond_to do |format|
			if params[:home] == "true"
				format.html { 
					render :partial => 'excursions/home/catalogue', :locals =>{:@all_categories => @all_categories } 
				}
			else
      			format.all { render :layout => 'catalogue' }
    		end
    	end
	end


	def show
		@category = params[:category]	
		@excursions = search(@category, LIMIT_IN_SHOW)		
		respond_to do |format|
			if params[:home]== "true"
      		format.html { render :partial => 'excursions/home/show' }
    		else
    		format.all { render :layout => 'catalogue' }
    		end
    	end
	end


	private

	def search the_query, limit
		page =  1 #only the first 7
		mode = :extended
    	key = "excursions"

		SocialStream::Search.search(the_query,
		                            current_subject,
		                            mode:  mode,
		                            key:   key,
		                            page:  page,
		                            limit: limit,
		                            order: 'ranking DESC')

	end

end
