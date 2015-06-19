class CatalogueController < ApplicationController

  def index
    redirect_to "/search?catalogue=true"
  end

end
