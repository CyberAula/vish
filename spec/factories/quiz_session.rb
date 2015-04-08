include ActionDispatch::TestProcess

Factory.define :quizsession do |u|
	u.sequence(:name) { |n| "name#{ n }" }
 	u.sequence(:quiz) { |n| "desc#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 'Writely') }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely') }
end