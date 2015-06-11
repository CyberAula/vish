require 'spec_helper'

describe QuizSession, models:true do

	before do
		@quiz = Factory(:quizSession)
	end

	it 'title?' do
		assert_false @quiz.name.blank?
	end

	it 'description?' do
		assert_false @quiz.quiz.blank?
	end

	it 'url?' do 
		assert_false @quiz.url.nil?
	end

end

describe QuizAnswer, models:true do

	before do
		@quizanswer = Factory(:quizAnswer)
	end

	it 'answer?' do
		assert_false @quizanswer.answer.blank?
	end

	it 'belongs2?' do
		assert_false @quizanswer.quiz_session.blank?
	end

end
