require 'spec_helper'

describe QuizSession do

	before do
		@quiz = Factory(:quiz_session)
	end

	it 'title?' do
		!@quiz.title.blank?
	end

	it 'description?' do
		!@quiz.description.blank?
	end

	it 'activity_object?' do 
		!@quiz.activity_object.nil?
	end

end
