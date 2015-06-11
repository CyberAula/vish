require 'spec_helper'

describe Writing, models:true do
	before do
		@writing = Factory(:writing)
	end

	it 'title?' do
		assert_false @writing.fulltext.blank?
	end

	it 'description?' do
		assert_false @writing.plaintext.blank?
	end

	it 'activity_object?' do 
		assert_false @writing.activity_object.nil?
	end
end
