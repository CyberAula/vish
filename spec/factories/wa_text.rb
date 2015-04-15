include ActionDispatch::TestProcess

Factory.define :waText do |u|
	u.sequence(:fulltext) { |n| "name#{ n }" }
 	u.sequence(:plaintext) { |n| "desc#{ n }" }
 	#:O?
end#TODO