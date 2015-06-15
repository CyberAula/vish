require 'spec_helper'

describe Workshop, models:true, workshop:true, debug:true	 do
	before do
		@workshop = Factory(:workshop)
	end

	it 'title?' do
		assert_false @workshop.title.blank?
	end

	it 'draft?' do
		assert_false @workshop.draft.nil?
	end

	it 'activity_object?' do 
		assert_false @workshop.activity_object.nil?
	end
end

describe WorkshopActivity, models:true, workshop:true, debug:true  do
	before do
		@wa = Factory(:workshopActivity)
	end
	#problems because of polymorphic
	it 'title?' do
		assert_false @wa.title.blank?
	end

	it 'position?' do 
		assert_false @wa.position.nil?
	end

	it 'workshop_id?' do
		assert_false @wa.workshop_id.nil?
	end

	it 'description?' do
		assert_false @wa.description.nil?
	end

end

describe WaText, models:true, debug:true do
	before do
		@waTxt = Factory(:waText)
	end

	it 'fulltext?' do
		assert_false @waTxt.fulltext.blank?
	end

	it 'plaintext?' do
		assert_false @waTxt.plaintext.blank?
	end

end


describe WaAssignment, models:true, debug:true do
	before do
		@wass = Factory(:waAssignment)
	end

	it 'fulltext?' do
		assert_false @wass.fulltext.blank?
	end

	it 'plaintext?' do
		assert_false @wass.plaintext.blank?
	end

	it 'available_contributions?' do 
		assert_false @wass.available_contributions.blank?
	end
end

describe WaResource, models:true, debug:true do
	before do
		@wars = Factory(:waResource)
	end

	it 'fulltext?' do
		assert_false @wars.fulltext.blank?
	end

	it 'plaintext?' do
		assert_false @wars.plaintext.blank?
	end

	it 'available_contributions?' do 
		assert_false @wars.available_contributions.blank?
	end

end

describe WaResourcesGallery, models:true, debug:true do
	before do
		@warsgal = Factory(:waResourcesGallery)
	end

	it 'title?' do
		assert_false @warsgal.title.blank?
	end

end


describe WaContributionsGallery, models:true, debug:true do
	before do
		@wacngal = Factory(:waContributionsGallery)
	end

	it 'title?' do
		assert_false @wacngal.title.blank?
	end

	it 'activity_object?' do
		assert_false @wacngal.activity_object.nil?
	end
end