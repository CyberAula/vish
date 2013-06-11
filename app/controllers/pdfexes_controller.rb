class PdfexesController < ApplicationController

	def create
		@pdfex = Pdfex.new(params[:pdfex])
		@pdfex.save!
		@imgs = @pdfex.to_img(self)
		render :json => @imgs
	end

	def new
		@pdfex = Pdfex.new
	end

end