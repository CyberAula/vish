require 'spec_helper'

describe Category, models:true, slow:true do
  before do
  	@userTest = Factory(:user_vish, email: 'test2mail@gmail.com')
    @category = Factory(:category, author: @userTest.actor, owner: @userTest.actor )
    @user = Factory(:user_vish, email: 'testmail@gmail.com')
	@category_from_user = Factory(:category, author: @user.actor, owner: @user.actor)

	#user
	@excursion_user = FactoryGirl.build_stubbed(:excursion, author: @user.actor, owner: @user.actor)
	@picture_user = FactoryGirl.build_stubbed(:picture, author: @user.actor, owner: @user.actor)
	@video_user = FactoryGirl.build_stubbed(:video, author: @user.actor, owner: @user.actor)
	@audio_user = FactoryGirl.build_stubbed(:audio, author: @user.actor, owner: @user.actor)
	
	#other
	@excursion_other = FactoryGirl.build(:excursion)
	@picture_other = FactoryGirl.build(:picture)
	@video_other = FactoryGirl.build(:video)
	@audio_other = FactoryGirl.build(:audio)
  end

	context "when categorize" do
		it "is created" do
			#Rspec.reset
			assert_false @category.blank?
		end
	
		it "does comes from user created" do
			@category_from_user.author.should == (@user.actor)
		end

		it "does comes from user created, 2nd key" do
			(@category_from_user.owner).should == (@user.actor)
		end

		#THE EQUAL TO ZERO HAS BEEN DONE TO SPEED UP TESTS
		it "can categorize excursion from someone else" do
			@category_from_user.insertPropertyObject(@picture_other.activity_object)
			@category_from_user.property_objects[0].should be(@picture_other.activity_object)
		end
		it "can categorize image from someone else" do
			@category_from_user.insertPropertyObject(@excursion_other.activity_object)
			@category_from_user.property_objects[0].should be(@excursion_other.activity_object)
		end

		it "can categorize video from someone else" do
			@category_from_user.insertPropertyObject(@video_other.activity_object)
			@category_from_user.property_objects[0].should be(@video_other.activity_object)
		end

		it "can categorize audio from someone else" do
			@category_from_user.insertPropertyObject(@audio_other.activity_object)
			@category_from_user.property_objects[0].should be(@audio_other.activity_object)
		end

		it "can categorize excursion from user" do
			@category_from_user.insertPropertyObject(@excursion_user.activity_object)
			@category_from_user.property_objects[0].should be(@excursion_user.activity_object)
			@excursion_user.author.should == (@user.actor)
		end

		it "can categorize image from user" do
			@category_from_user.insertPropertyObject(@picture_user.activity_object)
			@category_from_user.property_objects[0].should be(@picture_user.activity_object)
			@picture_user.author.should == (@user.actor)
		end
		
		it "can categorize video from user" do
			@category_from_user.insertPropertyObject(@video_user.activity_object)
			@category_from_user.property_objects[0].should be(@video_user.activity_object) 
			@video_user.author.should == (@user.actor)
		end 
		
		it "can categorize audio from user" do 
			@category_from_user.insertPropertyObject(@audio_user.activity_object)
			@category_from_user.property_objects[0].should be(@audio_user.activity_object)
			@audio_user.author.should == (@user.actor)
		end

	end
end
