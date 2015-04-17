require 'spec_helper'

describe SpamReport, spam:true, models:true do

	before do
		@spamreport = Factory(:spamReport)
	end

	it 'fulltext?' do
		!@spamreport.issue.blank?
	end

	it 'activity_object?' do 
		!@spamreport.activity_object.nil?
	end

end
