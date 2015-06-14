require 'spec_helper'

describe LikesController, controllers: true do
#routes don't exist: new, edit,show,update
	
	before do
		@user = Factory(:user_vish)
		@excursion = Factory(:excursion)
	end

	it 'create a like' do 
		pending('it needs group and they dont seem to work in Vish, social stream inheritance')
		sign_in @user
		get :create, :id => @excursion.id , :user_id => @user.id, :group_id => 0
		assert_response :success
	end

	it 'destroy like' do
		pending('it needs group and they dont seem to work in Vish, social stream inheritance')
		sign_in @user
		get :destroy, :id => @excursion.id, :user_id => @user.id, :group_id => 0
		assert_response :success
	end


end
