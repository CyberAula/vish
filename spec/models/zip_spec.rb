require 'spec_helper'

describe Zip, models:true do

	before do
		@zipfile = Factory(:zipfile)
	end

	it 'title?' do
		assert_false @zipfile.title.blank?
	end

	it 'description?' do
		assert_false @zipfile.description.blank?
	end

	it 'activity_object?' do 
		assert_false @zipfile.activity_object.nil?
	end

end
