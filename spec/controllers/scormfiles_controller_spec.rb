require 'spec_helper'

describe ScormfilesController, controllers: true do


	before do
		@user = Factory(:user_vish )
		@scorm = Factory(:scormfile, :actor => @user.actor, :owner => @user.actor)	
	end

	it 'show' do 
		sign_in @user
		get :show, :id => @scorm.id
		assert_response :success
	end

	it 'update' do 
		sign_in @user
		post :update, :id => @scorm.id
		response.should redirect_to(@scorm)
	end

	it 'destroy' do 
		sign_in @user
		pending('it gets bugged in 152 models of scorm needs to be setted up')
		post :destroy, :id => @scorm.id
		response.should redirect_to(@user)
	end

end