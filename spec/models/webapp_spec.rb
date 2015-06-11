require 'spec_helper'

describe Webapp, models:true do

	before do
		@webapp = Factory(:webapp)
	end

	it 'title?' do
		assert_false @webapp.title.blank?
	end

	it 'description?' do
		assert_false @webapp.description.blank?
	end

	it 'activity_object?' do 
		assert_false @webapp.activity_object.nil?
	end

end
