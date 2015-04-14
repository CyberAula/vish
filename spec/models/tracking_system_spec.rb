require 'spec_helper'

describe TrackingSystemEntry, models:true do
	before do
		@tsEntry = Factory(:trackingSystemEntry)
	end

	it 'title?' do
		!@tsEntry.app_id.blank?
	end

	it 'data?' do
		!@tsEntry.data.blank?
	end

	it 'user_agent?' do 
		!@tsEntry.user_agent.nil?
	end

	it 'referrer?' do
		!@tsEntry.referrer.blank?
	end

	it 'user_logged?' do
		@tsEntry.user_logged
	end

end
