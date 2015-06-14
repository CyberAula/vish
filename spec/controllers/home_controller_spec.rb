require 'spec_helper'

describe HomeController, controllers: true do

	before do
		@user = Factory(:user_vish)
		sign_in @user
	end

	it 'asking for home as html' do
		get :index
		assert_response :success
	end

	it 'asking for home as html' do
		get :index, :tab => 'home', :page => 1
		assert_response :success
	end

	it 'asking for net as html' do
		get :index, :tab => 'net', :page => 1
		assert_response :success
	end

	it 'asking for net as html' do
		get :index, :tab => 'net'
		assert_response :success
	end

	it 'asking for home as json' do
		get :index, :tab => 'catalogue'
		assert_response :success
	end

end
