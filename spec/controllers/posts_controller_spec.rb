require 'spec_helper'

describe PostsController do
  include SocialStream::TestHelpers
  include SocialStream::TestHelpers::Controllers

  render_views

  describe "authorizing" do
    before :all do
      @ss_relation_model = SocialStream.relation_model
    end

    after :all do
      SocialStream.relation_model = @ss_relation_model
    end

    describe "in follow relation model" do
      before :all do
        SocialStream.relation_model = :follow
      end

      before do
        @user = Factory(:user)
        sign_in @user
      end

      describe "post from other user" do
        before do
          @current_model = Factory(:post)
        end

        it_should_behave_like "Allow Reading"
      end
    end

    describe "in custom relation mode" do
      before :all do
        SocialStream.relation_model = :custom
      end

      before do
        @user = Factory(:user)
        sign_in @user
      end

      describe "posts to user" do
        describe "with first relation" do
          before do
            contact = @user.contact_to!(@user)
            relation = @user.relation_customs.sort.first
            model_assigned_to @user.contact_to!(@user), relation
            @current_model = Factory(:post, :author_id => @user.actor_id,
                                     :owner_id  => @user.actor_id,
                                     :user_author_id => @user.actor_id,
                                     :relation_ids => Array(relation.id))
          end

          it_should_behave_like "Allow Creating"
          it_should_behave_like "Allow Reading"
          it_should_behave_like "Allow Destroying"

          it "should destroy with js" do
            count = model_count
            delete :destroy, :id => @current_model.to_param, :format => :js

            resource = assigns(model_sym)

            model_count.should eq(count - 1)
          end
        end

        describe "with last relation" do
          before do
            contact = @user.contact_to!(@user)
            relation = @user.relation_customs.sort.last
            model_assigned_to @user.contact_to!(@user), relation
            @current_model = Factory(:post, :author_id => @user.actor_id,
                                     :owner_id  => @user.actor_id,
                                     :user_author_id => @user.actor_id,
                                     :relation_ids => Array(relation.id))
          end

          it_should_behave_like "Allow Creating"
          it_should_behave_like "Allow Reading"
          it_should_behave_like "Allow Destroying"
        end

        describe "with public relation" do
          before do
            contact = @user.contact_to!(@user)
            relation = Relation::Public.instance
            model_assigned_to @user.contact_to!(@user), relation
            @current_model = Factory(:post, :author_id => @user.actor_id,
                                     :owner_id  => @user.actor_id,
                                     :user_author_id => @user.actor_id)
          end

          it_should_behave_like "Allow Creating"
          it_should_behave_like "Allow Reading"
          it_should_behave_like "Allow Destroying"
        end
      end

      describe "post to friend" do
        before do
          friend = Factory(:friend, :contact => Factory(:contact, :receiver => @user.actor)).sender

          model_assigned_to @user.contact_to!(friend), friend.relation_custom('friend')
          @current_model = Factory(:post, :author_id => @user.actor_id,
                                   :owner_id  => friend.id,
                                   :user_author_id => @user.actor_id)
        end

        it_should_behave_like "Allow Creating"
        it_should_behave_like "Allow Reading"
      end

      describe "post to acquaintance" do
        before do
          ac = Factory(:acquaintance, :contact => Factory(:contact, :receiver => @user.actor)).sender

          model_assigned_to @user.contact_to!(ac), ac.relation_custom('acquaintance')
        end

        it_should_behave_like "Deny Creating"
      end

      describe "post from other user" do
        before do
          @current_model = Factory(:post)
        end


        it_should_behave_like "Deny Reading"
      end
    end

    context "creating public post" do
      before do
        @post = Factory(:public_post)
      end

      it "should render" do
        get :show, :id => @post.to_param

        response.should be_success
      end
    end

  end
end
