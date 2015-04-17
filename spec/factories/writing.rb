include ActionDispatch::TestProcess

Factory.define :writing do |u|
	u.sequence(:fulltext) { |n| "plaintext#{ n }" }
 	u.sequence(:plaintext) { |n| "plaintext#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 'Writely') }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely') }
end