Rails.application.routes.draw do
  # Authentication routes should be first
  resource :session
  resources :passwords, param: :token

  # Public routes
  root "topics#index"
  
  resources :topics do
    collection do
      get :search
    end
    member do
      post :refresh_quotes
    end
  end
  
  # Root level quotes
  resources :quotes, only: [:index] do
    collection do
      get :search
    end
  end

  # Add people resources
  resources :people do
    resources :quotes, only: [:index]
    resources :books, only: [:index]
  end
  
  # Remove 'people' from the STI types list
  %w[places concepts things events actions others].each do |type|
    resources type, controller: 'topics', type: type.singularize.classify do
      scope module: :topics do
        resources :quotes, only: [:index, :create, :destroy] do
          collection do
            get 'search/wikiquotes', to: 'quotes/search#new'
            post 'search/wikiquotes', to: 'quotes/search#create'
            get 'search/brainyquotes', to: 'quotes/brainy_search#new'
            post 'search/brainyquotes', to: 'quotes/brainy_search#create'
          end
        end
      end
    end
  end
end
