include ActionDispatch::TestProcess

Factory.define :video do |u|
	u.sequence(:title) { |n| "name#{ n }" }
 	u.sequence(:description) { |n| "desc#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 't3st1ng_d3m0_n4m3') }
 	u.owner {|author| author.association(:user_vish, :name => 't3st1ng_d3m0_n4m3') }
 	u.file { fixture_file_upload 'spec/assets/test.mp4', 'video/mp4' }
end