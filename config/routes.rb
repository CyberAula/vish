Vish::Application.routes.draw do


  devise_for :users, :controllers => {:omniauth_callbacks => 'omniauth_callbacks', registrations: 'registrations'}

  resource :session_locale
  resource :spam_report

  resources :quiz_sessions do
    get "results", :on => :member
  end
  match 'quiz_sessions/:id/close' => 'quiz_sessions#close'
  match 'quiz_sessions/:id/delete' => 'quiz_sessions#delete'
  match 'quiz_sessions/:id/answer' => 'quiz_sessions#updateAnswers'
  match 'qs/:id' => 'quiz_sessions#show'

  match 'help' => 'help#index'
  match 'faq' => 'faq#index'
  match 'legal_notice' => 'legal_notice#index'
  match 'overview' => 'overview#index'
  
  match 'users/:user_id/resources' => 'users#resources'
  match 'users/:user_id/events' => 'users#events'
  match 'users/:user_id/categories' => 'users#categories'
  match 'users/:user_id/followers' => 'users#followers'
  match 'users/:user_id/followings' => 'users#followings'

  # Match the filter before the individual resources
  match 'excursions/search' => 'excursions#search'
  match 'excursions/recommended' => 'excursions#recommended'

  #resources :excursions
  
  match 'excursions/last_slide' => 'excursions#last_slide'
  match '/apis/iframe_api' => 'excursions#iframe_api'
  match '/apis/excursion_search' => 'excursions#cross_search'

  match '/excursions/thumbnails' => 'excursions#excursion_thumbnails'
  match '/excursion_thumbnails' => 'excursions#excursion_thumbnails'

  match 'excursions/preview' => 'excursions#preview'
 
  match 'excursions/:id/clone' => 'excursions#clone'
  
  match '/excursions/:id/evaluate' => 'excursions#evaluate'
  match '/excursions/:id/learning_evaluate' => 'excursions#learning_evaluate'
  
  match '/excursions/:id.mashme' => 'excursions#show', :defaults => { :format => "gateway", :gateway => 'mashme' }
  match '/excursions/:id.embed' => 'excursions#show', :defaults => { :format => "full" }

  #Download JSON
  match '/excursions/tmpJson' => 'excursions#uploadTmpJSON', :via => :post
  match '/excursions/tmpJson' => 'excursions#downloadTmpJSON', :via => :get

  match '/categories/add_items' => 'categories#add_items', :via => :post
  match '/categories/favorites' => 'categories#show_favorites'

  match 'resources/search' => 'resources#search'
  
  match 'lre/search' => 'lre#search_lre'

  #redirect /home.json to the original path
  #This way, ViSH Mobile login continue working
  match '/home.json' => 'home#index', :format => :json

  #redirect /home to /excursions
  match '/home' => 'excursions#index'

  #PDF to Excursion
  resources :pdfexes

  #Download the user manual and count the number of downloads
  match 'user_manual' => 'help#download_user_manual'

  resources :competitions
  resource :contest
  resources :contest_all
  resources :about

  match '/catalogue' => 'catalogue#index'
  match '/catalogue/:category' => 'catalogue#show'

  # Add this at the end so other URLs take prio
  match '/s/:id' => "shortener/shortened_urls#show"

  # for OAI-MPH
  mount OaiRepository::Engine => "/oai_repository"

  #LOEP
  namespace :loep do
    resources :los
  end


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
  # match ':controller(/:action(/:id))(.:format)'
end
