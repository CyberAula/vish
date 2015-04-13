include ActionDispatch::TestProcess

Factory.define :quizSession do |u|
	u.sequence(:name) { |n| "name#{ n }" }
 	u.sequence(:quiz) { |n| "desc#{ n }" }
 	u.sequence(:url) { |n| "http://sequence#{ n }" }
 	#u.author {|author| author.association(:user_vish, :name => 'Writely') }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely').actor }
end