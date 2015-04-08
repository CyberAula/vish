include ActionDispatch::TestProcess

Factory.define :quizanswer do |u|
 	u.sequence(:answer) { |n| "desc#{ n }" }
 	u.quiz_session { |qs| qs.association(:quiz_session) }
end