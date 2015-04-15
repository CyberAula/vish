require 'spec_helper'

describe Zip, models:true do

	before do
		@zipfile = Factory(:zipfile)
	end

	it 'title?' do
		!@zipfile.title.blank?
	end

	it 'description?' do
		!@zipfile.description.blank?
	end

	it 'activity_object?' do 
		!@zipfile.activity_object.nil?
	end

end
