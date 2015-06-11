require 'spec_helper'

describe EmbedsController, controllers: true do
                   # search_embeds GET      /embeds/search(.:format)                                             embeds#search
                   #        embeds GET      /embeds(.:format)                                                    embeds#index
                   #               POST     /embeds(.:format)                                                    embeds#create
                   #     new_embed GET      /embeds/new(.:format)                                                embeds#new
                   #    edit_embed GET      /embeds/:id/edit(.:format)                                           embeds#edit
                   #         embed GET      /embeds/:id(.:format)                                                embeds#show
                   #               PUT      /embeds/:id(.:format)                                                embeds#update
                   #               DELETE   /embeds/:id(.:format)                                                embeds#destroy
    before do
  		@user = Factory(:user_vish)
  	  @embed = Factory(:embed, author: @user.actor, owner: @user.actor )
    end
	
  	it 'embeds edit' do 
    	get :edit
  	end   
  	
     it 'embeds create with json' do
      sign_in @user
      get :create, :embed => { owner_id: @user.actor.id, title: "asdfsdas", description: "adsfasda", tag_list: [], language: "independent", age_min: 0, age_max: 0, scope: 0 }
      response.should redirect_to(Embed.last)
    end

  	it 'embeds show' do 
    	get :show, {id: @embed.id}
      assert_response :success
  	end

  	it 'embeds update' do
  		sign_in @user 
    	put :update, :embed => { owner_id: @user.actor.id, title: "asdfsdas", description: "adsfasda", tag_list: [], language: "independent", age_min: 0, age_max: 0, scope: 0 }, :id => @embed.id
      response.should redirect_to(@embed)
  	end

  	it 'embeds destroy' do 
      sign_in @user 
    	get :destroy, :id => @embed.id
      response.should redirect_to(@user)
  	end   
  		
end
