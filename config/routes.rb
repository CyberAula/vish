Vish::Application.routes.draw do
  # Match the filter before the individual resources
  match 'excursions/search' => 'excursions#search'

  resources :excursions

  resources :slides

  resources :embeds

  resources :office_documents do
    get "search",   :on => :collection
    get "download", :on => :member
  end

  resources :quiz_sessions do
    get "results", :on => :member
  end

  match 'resources/search' => 'resources#search'

  match 'followers/search' => 'followers#search_followers'
  match 'followings/search' => 'followers#search_followings'

  devise_for :users, :controllers => {:omniauth_callbacks => 'omniauth_callbacks'}

  SocialStream.subjects.each do |actor|
    resources actor.to_s.pluralize do
      match 'followings' => 'followers#index', :as => :followings, :defaults => { :direction => 'sent' }
      match 'followers' => 'followers#index', :as => :followers, :defaults => { :direction => 'received' }
      match 'modal' => 'modals#actor'
    end
  end

  resource :session_locale

  match 'legal_notice' => 'legal_notice#index'

  match 'mashme_invite' => 'mashme_invites#invite'

  match 'help' => 'help#index'

  # Add this at the end so other URLs take prio
  match '/s/:id' => "shortener/shortened_urls#show"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
