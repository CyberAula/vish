class PdfexesController < ApplicationController
  before_filter :authenticate_user_on_pdfexe
  before_filter :fill_create_params, :only => [ :new, :create]

  def new
    @pdfex = Pdfex.new
  end

  def create
    @pdfex = Pdfex.new(params[:pdfex])
    @pdfex.save!
    begin
    	@imgs = @pdfex.to_img(self)
    	render :json => @imgs
    rescue Exception => e
    	@pdfex.destroy
    	render :json => e.message
    end
  end

  def show
    @pdfex = Pdfex.find(params[:id])
    render :json => @pdfex.getImgArray
  end


  private

  def authenticate_user_on_pdfexe
    unless user_signed_in?
      raise "#PDFexAPIError:4 Unauthorized"
    end
  end

  def fill_create_params
    params["pdfex"] ||= {}
    params["pdfex"]["owner_id"] = current_subject.actor_id

    if params["pdfex"]["scope"]
      #Param not used in pdfexes
      params["pdfex"].delete "scope"
    end
  end

end