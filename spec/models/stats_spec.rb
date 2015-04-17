require 'spec_helper'

describe Stats, models:true do
	before do
		@stats = Factory(:stats)
	end

	it 'name?' do
		!@stats.stat_name.blank?
	end

	it 'value?' do
		!@stats.stat_value.blank?
	end

end
