class Loep::LosController < Loep::BaseController
  before_filter :authenticate_app

  # GET /loep/los/:id
  def show
    respond_to do |format|
        format.any { 
          render json: "Ok"
        }
    end
  end

  # PUT /loep/los/:id
  def update
    #New information about this LO is available on LOEP (e.g. a new evaluation and/or metric)
    lo = ActivityObject.getObjectFromGlobalId(params[:id]) rescue nil
    return render json: "Resource not found", :status => 404 if lo.nil?  #This lo does not exist

    eEvData = JSON(params["lo"])

    # Interesting information
    # eEvData["Completed Evaluations with LORI v1.5"]
    # eEvData["Metric Score: LORI Arithmetic Mean"]
    # eEvData["Metric Score: LORI WAM CW"]

    # eEvData["LORI v1.5 item1"]
    # ...
    # eEvData["LORI v1.5 item9"]

    VishLoep.fillActivityObjectMetrics(lo.activity_object,eEvData)

    respond_to do |format|
        format.any { 
          render json: "Done"
        }
    end
  end

end
