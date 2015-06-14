require 'spec_helper'

describe UsersController, controllers: true do

	before do
      @user = Factory(:user_vish)
      sign_in @user
    end

	it 'index' do 
    	lambda { get :index }.should raise_error
    end

	it 'excursions' do 
    	get :excursions
    	assert_response :success
    end

   it 'workshops' do 
    	get :workshops
    	assert_response :success
    end

    it 'events' do 
    	get :events
    	assert_response :success
    end

      it 'resources' do 
    	get :resources
    	assert_response :success
    end

     it 'categories' do 
    	get :categories
    	assert_response :success
    end

    it 'followers' do 
    	get :followers
    	assert_response :success
    end

    it 'followings' do 
    	get :followings
    	assert_response :success
    end
    
	it 'current' do 
    	get :current
    	assert_response 406
    end
    
    it 'promote' do 
    	pending('needs to be admin')
    	get :promote
    	assert_response :success
    end
    
    it 'degrade' do 
    	pending('needs to be admin')
    	get :degrade
    	assert_response :success
    end

    it 'destroy' do 
    	pending('needs to be admin')
    	get :destroy
    	assert_response :success
    end
end