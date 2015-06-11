require 'spec_helper'

describe CatalogueController, controllers: true do

	describe 'index' do
		it 'get show' do
			get :index
			assert_response :success
			expect(response).to render_template("catalogue")
		end

		it 'get index' do
			get :index, :locals => {:category => true}
			assert_response :success
			expect(response).to render_template("layouts/catalogue")
		end

		it 'render catalogue layout' do
			get :index, :locals => {:is_home => true}
			assert_response :success
			expect(response).to render_template("catalogue/index")
		end
	end

	describe 'show' do
		it 'get show' do
			get :show
			assert_response :success
		end
	end
end
