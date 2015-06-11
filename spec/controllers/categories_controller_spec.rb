require 'spec_helper'

describe CategoriesController, controllers: true do
	#TODO
	render_views

    before do
      @user = Factory(:user_vish)
      sign_in @user
    end

	describe "renders" do
		it "user categories" do
			get :index
			expect(response).to redirect_to(user_path(@user) + "?tab=categories")
		end

		it "show_favorites" do 
			get :show_favorites
      		assert_response 200
			expect(response).to render_template("favorites")
		end
	end

end
