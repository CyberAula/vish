require 'spec_helper'

describe TrackingSystemEntry, models:true do
	before do
		@tsEntry = Factory(:trackingSystemEntry)
	end

	it 'title?' do
		assert_false @tsEntry.app_id.blank?
	end

	it 'data?' do
		assert_false @tsEntry.data.blank?
	end

	it 'user_agent?' do 
		assert_false @tsEntry.user_agent.nil?
	end

	it 'referrer?' do
		assert_false @tsEntry.referrer.blank?
	end

	it 'user_logged?' do
		@tsEntry.user_logged
	end

end
