require 'spec_helper'

describe PdfexesController, controllers: true do
#TODO

	before do
		@user = Factory(:user_vish)
	end
	

	it 'new' do 
		sign_in @user
		get :new
		assert_response :success
	end


	it 'create' do 
		sign_in @user
		pending('string doesnt match?')
		get :create, :pdfex => 'test'
		assert_response :failure
	end


	it 'show' do 
		sign_in @user
		pending('pdfex factory doesnt have img_array')
		pdfex = Factory(:pdfex)
		get :show, :id => pdfex.id
		assert_response :success
	end

end
