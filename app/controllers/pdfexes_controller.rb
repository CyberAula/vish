class PdfexesController < ApplicationController

	def show
		unless user_signed_in?
			raise "#PDFexAPIError:4 Unauthorized"
		end

		@pdfex = Pdfex.find(params[:id])
		render :json => @pdfex.getImgArray
	end

	def create
		unless user_signed_in?
			raise "#PDFexAPIError:4 Unauthorized"
		end

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

	def new
		unless user_signed_in?
			raise "#PDFexAPIError:4 Unauthorized"
		end
		
		@pdfex = Pdfex.new
	end

end