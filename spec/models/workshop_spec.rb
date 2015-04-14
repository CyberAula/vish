require 'spec_helper'

describe Workshop, models:true do
	before do
		@workshop = Factory(:workshop)
	end

	it 'title?' do
		!@workshop.title.blank?
	end

	it 'draft?' do
		!@workshop.draft.nil?
	end

	it 'activity_object?' do 
		!@workshop.activity_object.nil?
	end
end

describe WorkshopActivity, models:true do
	before do
		@wact = Factory(:workshopActivity)
	end

	it 'title?' do
		!@wact.title.blank?
	end

	it 'position?' do 
		!@wact.position.nil?
	end

	it 'workshop_id?' do
		!@wact.workshop_id.nil?
	end

	it 'wa_id?' do
		!@wact.wa_id.nil?
	end

	it 'wa_type?' do
		!@wact.wa_type.nil?
	end

	it 'description?' do
		!@wact.description.nil?
	end

end

describe WaText, models:true do
	before do
		@waTxt = Factory(:waText)
	end

	it 'fulltext?' do
		!@waTxt.fulltext.blank?
	end

	it 'plaintext?' do
		!@waTxt.plaintext.blank?
	end

end


describe WaAssignment, models:true do
	before do
		@wass = Factory(:waAssignment)
	end

	it 'fulltext?'
	#	!@wass.fulltext.blank?

	it 'plaintext?'
	#	!@wass.plaintext.blank?

	it 'available_contributions?'
	#	!@wass.available_contributions.blank?
end

describe WaResource, models:true do
	before do
		@wars = Factory(:waResource)
	end

	it 'fulltext?' 
	#	!@wars.fulltext.blank?

	it 'plaintext?'
	#	!@wars.plaintext.blank?

	it 'available_contributions?'
	#	!@wars.available_contributions.blank?

end

describe WaResourcesGallery, models:true do
	before do
		@warsgal = Factory(:waResourcesGallery)
	end

	it 'title?' do
		!@warsgal.title.blank?
	end

end


describe WaContributionsGallery, models:true do
	before do
		@wacngal = Factory(:waContributionsGallery)
	end

	it 'title?'
	#	!@wacngal.title.blank?

	it 'activity_object?' 
	#	!@wacngal.activity_object.nil?
end