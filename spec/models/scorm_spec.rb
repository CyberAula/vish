require 'spec_helper'

describe Scorm do
	before do
		@scorm = Factory(:scormfile)
	end

	it 'title?' do
		assert_false @scorm.title.blank?
	end

	it 'description?' do
		assert_false @scorm.description.blank?
	end

	it 'activity_object?' do 
		assert_false @scorm.activity_object.nil?
	end
end
