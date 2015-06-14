require 'spec_helper'

describe SpamReportsController, controllers: true do
	
	before do 
		@user = Factory(:user_vish)
		@spam = Factory(:spamReport, reporter_actor_id: @user.id )
	end

	it 'index' do 
		sign_in @user 
		get :index
		response.should redirect_to(:admin)
		assert_response :redirect
	end

	it 'update' do
		pending('depends on admin like admin pages')
		sign_in @user 
		post :update, :id => @spam.id
		assert_response :redirect
	end
	
	it 'create' do
		pending('depends on admin like admin pages')
		sign_in @user 
		post :create		
		assert_response :redirect
	end

	it 'open' do
		pending('depends on admin like admin pages')
		sign_in @user 
		get :open, :id => @spam.id
		assert_response :redirect
	end
 
	it 'close' do
		pending('depends on admin like admin pages')
		sign_in @user 
		get :close, :id => @spam.id
		assert_response :redirect
	end

	it 'destroy' do
		pending('depends on admin like admin pages')
		sign_in @user 
		post :destroy, :id => @spam.id
		assert_response :redirect
	end

end