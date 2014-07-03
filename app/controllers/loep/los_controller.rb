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
    excursion = Excursion.find(params[:id]) rescue nil

    if excursion.nil?
      #This excursion does not exist
      return
    end

    eEvData = JSON(params["lo"])

    # Interesting information
    # eEvData["Completed Evaluations with LORI v1.5"]
    # eEvData["Metric Score: LORI Arithmetic Mean"]
    # eEvData["Metric Score: LORI Weighted Arithmetic Mean"]

    # eEvData["LORI v1.5 item1"]
    # ...
    # eEvData["LORI v1.5 item9"]

    if eEvData["Metric Score: LORI Weighted Arithmetic Mean"].is_a? Float
      excursion.activity_object.update_column :reviewers_qscore, eEvData["Metric Score: LORI Weighted Arithmetic Mean"]
    end

    if eEvData["Metric Score: WBLT-S Weighted Arithmetic Mean"].is_a? Float
      excursion.activity_object.update_column :users_qscore, eEvData["Metric Score: WBLT-S Weighted Arithmetic Mean"]
    end

    excursion.calculate_qscore

    respond_to do |format|
        format.any { 
          render json: "Ok"
        }
    end
  end

end
