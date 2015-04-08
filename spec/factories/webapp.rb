include ActionDispatch::TestProcess

Factory.define :webapp do |u|
	u.sequence(:title) { |n| "name#{ n }" }
 	u.sequence(:description) { |n| "desc#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 'Writely') }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely') }
 	u.file { fixture_file_upload 'spec/assets/test_webapp.zip', 'file/zip' }
end