require 'spec_helper'

describe Pdfex, models:true do

	before do
		@pdfex = Factory(:pdfex)
	end

	it 'file_type?' do
		@pdfex.attach_content_type == "application/pdf"
	end

	it 'file?' do 
		@pdfex.attach_file_name == "test_pdf.pdf"
	end

end
