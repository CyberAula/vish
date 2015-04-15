include ActionDispatch::TestProcess

Factory.define :pdfex do |u|
	u.sequence(:attach_file_name) { |n| "name#{ n }" }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely').actor }
 	u.attach { fixture_file_upload 'spec/assets/test_pdf.pdf', 'application/pdf' }
end