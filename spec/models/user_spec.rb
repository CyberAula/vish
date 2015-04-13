require 'spec_helper'

describe User, models:true do
	before do
		@user = Factory(:user_vish)
		@user2 = Factory(:user_vish)
	end

	it "is created" do
		User.first == @user 
	end

	it "is also an activity_object" do
		@user.activity_object.class == ActivityObject
	end

	it "has an actor associated" do 
		@user.actor.class == Actor
	end

	it "can follow other user" do
		@user.followers << @user2.actor
		@user.followers == 1
	end	

	it "can be followed by other user" do
		@user.followings << @user2.activity_object
		@user.followers == 1
	end

	it "can be gone from platform" do
		count = User.count
		@user.destroy
		User.count == (count - 1)
	end

end
