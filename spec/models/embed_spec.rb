require 'spec_helper'

describe Embed, models:true do

	before do
		@embed = Factory(:embed)
	end

	it 'fulltext?' do
		assert_false @embed.fulltext.blank?
	end

	it 'activity_object?' do 
		assert_false @embed.activity_object.nil?
	end

end
