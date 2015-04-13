require 'spec_helper'

describe Swf, models:true do
	before do
		@swf = Factory(:swf)
	end

	it 'title?' do
		!@swf.title.blank?
	end

	it 'description?' do
		!@swf.description.blank?
	end

	it 'activity_object?' do 
		!@swf.activity_object.nil?
	end
end
