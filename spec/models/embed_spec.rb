require 'spec_helper'

describe Embed, models:true do

	before do
		@embed = Factory(:embed)
	end

	it 'fulltext?' do
		!@embed.fulltext.blank?
	end

	it 'activity_object?' do 
		!@embed.activity_object.nil?
	end

end
