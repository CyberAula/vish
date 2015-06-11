require 'spec_helper'

describe Officedoc, models:true do

	before do
		@Odoc = Factory(:officedoc)
	end

	it 'title?' do
		assert_false @Odoc.title.blank?
	end

	it 'description?' do
		assert_false @Odoc.description.blank?
	end

	it 'activity_object?' do 
		assert_false @Odoc.activity_object.nil?
	end

end
