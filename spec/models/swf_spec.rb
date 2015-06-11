require 'spec_helper'

describe Swf, models:true do
	before do
		@swf = Factory(:swf)
	end

	it 'title?' do
		assert_false @swf.title.blank?
	end

	it 'description?' do
		assert_false @swf.description.blank?
	end

	it 'activity_object?' do 
		assert_false @swf.activity_object.nil?
	end
end
