require 'spec_helper'

describe Quiz do

	before do
		@quiz = Factory(:quiz_session)
	end

	it 'file_type?' do
		@pdfex.attach_content_type == "application/pdf"
	end

	it 'file?' do 
		@pdfex.attach_file_name == "test_pdf.pdf"
	end

end
