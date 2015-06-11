require 'spec_helper'

describe EmbedsController, controllers: true, debug:true do
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
	end
	
  	it 'embeds edit' do 
    	get :edit
  	end   
  	it 'embeds create' do
  		sign_in @user
  		get :create
  		assert_response(action(:new))
  	end

  	it 'embeds show' do 
    	get :show
  	end

  	it 'embeds update' do
  		sign_in @user 
    	get :update
  	end   
  	it 'embeds destroy' do 
    	get :destroy
  	end   
  		
end
