require 'spec_helper'

describe QuizSession, models:true do

	before do
		@quiz = Factory(:quizSession)
	end

	it 'title?' do
		!@quiz.name.blank?
	end

	it 'description?' do
		!@quiz.quiz.blank?
	end

	it 'url?' do 
		!@quiz.url.nil?
	end

end

describe QuizAnswer, models:true do

	before do
		@quizanswer = Factory(:quizAnswer)
	end

	it 'answer?' do
		!@quizanswer.answer.blank?
	end

	it 'belongs2?' do
		!@quizanswer.quiz_session.blank?
	end

end
