include ActionDispatch::TestProcess

Factory.define :quizAnswer do |u|
 	u.sequence(:answer) { |n| "desc#{ n }" }
 	u.quiz_session { |qs| qs.association(:quizSession) }
end