require 'spec_helper'

describe QuizSessionsController, controllers: true do
#TODO

	before do
		@user = Factory(:user_vish)
		@quiz_session = Factory(:quizSession)
	end

	it 'get index' do
		sign_in @user
		get :index
		assert_response :success
	end

	it 'create' do
		sign_in @user
		post :create, :name => 'test_session', :quiz => { 'firstquiz' => 'im_a_jsonsogood'}
		assert_response :success
		QuizSession.last.name.should == 'test_session'
	end

	it 'edit' do
		sign_in @user
		get :edit, :id => @quiz_session.id
		assert_response :success
	end

	it 'update' do
		sign_in @user
		get :update, :id => @quiz_session.id
		assert_response :success
	end

	it 'close' do
		sign_in @user
		get :close, :id => @quiz_session.id
		assert_response :success
		QuizSession.where(id: @quiz_session.id) == nil
	end

	it 'delete' do
		sign_in @user
		get :delete, :id => @quiz_session.id
		assert_response :success
		QuizSession.where(id: @quiz_session.id) == nil
	end


	it 'results' do
		sign_in @user
		get :results, :id => @quiz_session.id
		assert_response :success
	end

	it 'show' do 
		sign_in @user
		get :show, :id => @quiz_session.id
		assert_response :success
	end

	it 'updateAnswers' do
		sign_in @user
		post :updateAnswers, :id => @quiz_session.id, :name => 'test_session', :quiz => { 'firstquiz' => 'im_a_jsonsogood'}
		assert_response :success
		JSON.parse(response.body)["processed"].should == false
	end

end