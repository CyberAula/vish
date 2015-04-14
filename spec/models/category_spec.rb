require 'spec_helper'

describe Category, models:true do
  before do
    @category = Factory(:category)
  end


	it "is created" do
		!@category.blank?
	end

	context "Categorizing stuff" do
		before(:each) do
			@user = Factory(:user_vish)
			@category_from_user = Factory(:category, author: @user.actor, owner: @user.actor)
			
			#user
			@excursion_user = Factory(:excursion, author: @user.actor, owner: @user.actor)
			@picture_user = Factory(:picture, author: @user.actor, owner: @user.actor)
			@video_user = Factory(:video, author: @user.actor, owner: @user.actor)
			@audio_user = Factory(:audio, author: @user.actor, owner: @user.actor)
			
			#other
			@excursion_other = Factory(:excursion)
			@picture_other = Factory(:picture)
			@video_other = Factory(:video)
			@audio_other = Factory(:audio)
		end
		
		it "does comes from user created" do
			@category_from_user.author == @user.actor
		end

		it "does comes from user created, 2nd key" do
			@category_from_user.owner == @user.actor
		end

		#THE EQUAL TO ZERO HAS BEEN DONE TO SPEED UP TESTS
		it "can categorize excursion from someone else" do
			@category_from_user.insertPropertyObject(@picture_other.activity_object)
			@category_from_user.property_objects[0] == @picture_other
		end
		it "can categorize image from someone else" do
			@category_from_user.insertPropertyObject(@excursion_other.activity_object)
			@category_from_user.property_objects[0] == @excursion_other
		end

		it "can categorize video from someone else" do
			@category_from_user.insertPropertyObject(@video_other.activity_object)
			@category_from_user.property_objects[0] == @video_other
		end

		it "can categorize audio from someone else" do
			@category_from_user.insertPropertyObject(@audio_other.activity_object)
			@category_from_user.property_objects[0] == @audio_other
		end

		it "can categorize excursion from user" do
			@category_from_user.insertPropertyObject(@excursion_user.activity_object)
			@category_from_user.property_objects[0] == @excursion_user and @excursion_user.author == @user
		end

		it "can categorize image from user" do
			@category_from_user.insertPropertyObject(@picture_user.activity_object)
			@category_from_user.property_objects[0] == @picture_user and @picture_user.author == @user
		end
		
		it "can categorize video from user" do
			@category_from_user.insertPropertyObject(@video_user.activity_object)
			@category_from_user.property_objects[0] == @video_user and @video_user.author == @user
		end 
		
		it "can categorize audio from user" do 
			@category_from_user.insertPropertyObject(@audio_user.activity_object)
			@category_from_user.property_objects[0] == @audio_user and @audio_user.author == @user
		end

	end
end
