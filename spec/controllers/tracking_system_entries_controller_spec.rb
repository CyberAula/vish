require 'spec_helper'

describe TrackingSystemEntriesController, controllers: true do


	before do
      @user = Factory(:user_vish)
      sign_in @user
    end

    it 'index' do 
    	get :index
    	assert_response :success
    end

    it 'create' do 
    	post :create
    	assert_response :success
    end

end