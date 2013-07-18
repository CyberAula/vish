require 'spec_helper'

describe ProfilesController do
  include SocialStream::TestHelpers
  render_views

  context "for a user" do
    before do
      @user = Factory(:user)
      sign_in @user
    end

    it "should render show" do
      get :show

      assert_response :success
    end

    it "should render show with user param" do
      get :show, :user_id => @user.to_param

      assert_response :success
    end

    it "should update" do
      put :update, :user_id => @user.to_param, :profile => { :organization => "Social Stream" }

      response.should redirect_to([@user, :profile])
    end

    it "should update via AJAX" do
      put :update, :user_id => @user.to_param, :profile => { :organization => "Social Stream" }, :format => :js

      response.should be_success
    end


    it "should not update other's" do
      begin
        put :update, :user_id => Factory(:user).to_param, :profile => { :organization => "Social Stream" }

        assert false
      rescue CanCan::AccessDenied
        assert true
      end
    end

  end
  
end

