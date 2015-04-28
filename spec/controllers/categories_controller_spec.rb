require 'spec_helper'

describe CategoriesController, controllers: true do
	render_views

    before do
      @user = Factory(:user_vish)
      sign_in @user
    end

	describe "renders" do
		it "user categories" do
			get :index
			expect(response).to url_for(current_subject) + "?tab=categories"
		end

		it "show_favourites" do 
			get :favourites
			 expect(subject).to redirect_to(assigns(:favourites))
		end
	end


end
