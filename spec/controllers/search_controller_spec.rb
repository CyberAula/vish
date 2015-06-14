require 'spec_helper'

describe SearchController, controllers: true do
	#the problem of testing a controller is that you really need to create complex scenarios where
	# it satisfies our conditions,i'm going to make base cases, then it can go more and more complicated
	before do
      @user = Factory(:user_vish)
      
    end

	it 'index' do
		sign_in @user
		get :index
		assert_response :success
	end

	it 'advanced' do 
		sign_in @user
		get :advanced
		assert_response :success
	end
	

end