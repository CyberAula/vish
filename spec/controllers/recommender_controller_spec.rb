require 'spec_helper'

describe RecommenderController, controllers: true do

	before do
		@user = Factory(:user_vish)
		@excursion = Factory(:excursion)
	end

	it 'simple petition' do
		sign_in @user
		get :api_resource_suggestions, :id => Excursion.last.object_id
		assert_response :success
	end

end