require 'spec_helper'

describe Webapp, models:true do

	before do
		@webapp = Factory(:webapp)
	end

	it 'title?' do
		!@webapp.title.blank?
	end

	it 'description?' do
		!@webapp.description.blank?
	end

	it 'activity_object?' do 
		!@webapp.activity_object.nil?
	end

end
