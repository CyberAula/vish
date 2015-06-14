require 'spec_helper'

describe TagsController, controllers: true do
	

	before do 
		@user = Factory(:user_vish)
	end

	it 'bad index' do 
		sign_in @user
		get :index
		assert_response 406
	end

	it 'index' do 
		sign_in @user
		get :index, :q => 'test', :mode => 'popular'
		pending('doesnt search for tags with params')
		assert_response 200
	end
end