require 'spec_helper'

describe Officedoc, models:true do

	before do
		@Odoc = Factory(:officedoc)
	end

	it 'title?' do
		!@Odoc.title.blank?
	end

	it 'description?' do
		!@Odoc.description.blank?
	end

	it 'activity_object?' do 
		!@Odoc.activity_object.nil?
	end

end
