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
      get 'people/search/:source', to: 'people#search', as: :search_people
      post 'people/:source', to: 'people#create', as: :create_person
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
        
        # Add people routes in the same style
        resources :people, only: [:index, :create, :destroy] do
          collection do
            get 'search/tmdb', to: 'people/search#new'
            post 'search/tmdb', to: 'people/search#create'
          end
        end
      end
    end
  end

  resources :concepts, controller: 'topics', as: 'topics' do
    namespace :people do
      resource :search, only: [:create] do
        collection do
          post 'tmdb'
        end
      end
    end
  end
end
