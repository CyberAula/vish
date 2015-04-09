require 'spec_helper'

describe Scorm do
	before do
		@scorm = Factory(:scormfile)
	end

	it 'title?' do
		!@scorm.title.blank?
	end

	it 'description?' do
		!@scorm.description.blank?
	end

	it 'activity_object?' do 
		!@scorm.activity_object.nil?
	end
end
