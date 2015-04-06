require 'spec_helper'

describe Pdfex do

	before do
		@pdf = Factory(:pdfex)
	end

	it 'activity_object_not_working?'

	it 'file_type?' do
		@pdf.attach_content_type == "application/pdf"
	end

	it 'file?' do 
		@pdf.attach_file_name == "test_pdf.pdf"
	end

end
