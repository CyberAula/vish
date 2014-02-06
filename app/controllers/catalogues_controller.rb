class CataloguesController < ApplicationController

	def show
		

		respond_to do |format|
      		format.all { render :layout => 'search' }
    	end
	end


end
