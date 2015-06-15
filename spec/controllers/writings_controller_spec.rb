require 'spec_helper'

describe WritingsController, controllers: true do
	
	before do
		@user = Factory(:user_vish)
		@writings = Factory(:writing, :actor => @user.actor, :owner => @user.actor )
	end

	it 'create' do
		sign_in @user
		get :create
		assert_response :redirect
		response.should redirect_to(Writing.last)
	end

	it 'destroy' do
		sign_in @user
		get :destroy, :id => @writings.id
		assert_response :redirect
		response.should redirect_to(@user)
		Writing.where(id: @writings.id ).should_not exist
	end


end