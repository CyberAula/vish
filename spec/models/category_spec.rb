require 'spec_helper'

describe Category do
  before do
    @category = Factory(:category)
  end


	it "is created" do
		!@category.blank?
	end

	context "Categorizing stuff" do
		before do
			@user = Factory(:user_vish)
			@category_from_user = Factory(:category, author: @user.actor, owner: @user.actor)
		end
		
		it "does comes from user created" do
			@category_from_user.author == @user.actor
		end

		it "does comes from user created, 2nd key" do
			@category_from_user.owner == @user.actor
		end

		it "can categorize excursion from someone else"
		it "can categorize excursion from oneself"
		it "can categorize image from someone else"
		it "can categorize image from him"
		it "can categorize video from someone else"
		it "can categorize video from him"
		it "can categorize audio from someone else"
		it "can categorize audio from him"
		
	end
end
