require 'spec_helper'

describe Workshop do
	before do
		@workshop = Factory(:workshop)
	end

	it 'title?' do
		!@workshop.title.blank?
	end

	it 'activity_object?' do 
		!@workshop.activity_object.nil?
	end
end
