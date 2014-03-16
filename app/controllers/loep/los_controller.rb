class Loep::LosController < Loep::BaseController
  before_filter :authenticate_app

  # GET /loep/los/:id
  def show
    respond_to do |format|
        format.any { 
          render json: "Show Method: Success"
        }
    end
  end

  # PUT /loep/los/:id
  def update
    #New information about this LO is available on LOEP (e.g. a new evaluation and/or metric)
    # @lo = Lo.find(params[:id])
    respond_to do |format|
        format.any { 
          render json: "Update Method: Success"
        }
    end
  end

end
