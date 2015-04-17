include ActionDispatch::TestProcess

Factory.define :audio do |u|
	u.sequence(:title) { |n| "name#{ n }" }
 	u.sequence(:description) { |n| "desc#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 'Writely') }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely') }
 	u.file { fixture_file_upload 'spec/assets/test.mp3', 'audio/mp3' }
end