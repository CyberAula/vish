require 'spec_helper'

describe Document do
	before do
		@picture = Factory(:picture)
	end

	it 'title?' do
		!@picture.title.blank?
	end
	it 'description?'
	it 'activity_object?'
end
