include ActionDispatch::TestProcess

Factory.define :officedoc do |u|
	u.sequence(:title) { |n| "name#{ n }" }
 	u.sequence(:description) { |n| "desc#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 't3st1ng_d3m0_n4m3') }
 	u.owner {|author| author.association(:user_vish, :name => 't3st1ng_d3m0_n4m3') }
 	u.file { fixture_file_upload 'spec/assets/test_pdf.pdf', 'application/pdf' }
end