require 'spec_helper'

describe User do
before do
	@user = Factory(:user_vish)
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

context "creating excursion" do
	before do
			@user2 = Factory(:user_vish)
			@excursion = Factory(:excursion, user: @user2)
		end
	it "can create excursion" do		
		#binding.pry
	end
end
it "can create event"
it "can create Document"
it "can create Category"
it "can follow other user"
it "can be followed by other user"
it "can be gone from platform"

end
