include ActionDispatch::TestProcess

Factory.define :stats do |u|
	u.sequence(:stat_name) { |n| "name#{ n }" }
 	u.stat_value { rand(20..100) }
end