require 'spec_helper'

describe Writing, models:true do
	before do
		@writing = Factory(:writing)
	end

	it 'title?' do
		!@writing.fulltext.blank?
	end

	it 'description?' do
		!@writing.plaintext.blank?
	end

	it 'activity_object?' do 
		!@writing.activity_object.nil?
	end
end
