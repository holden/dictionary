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
    collection do
      get 'search/tmdb', to: 'people/tmdb_search#new'
      post 'search/tmdb', to: 'people/tmdb_search#create'
      get 'search/knowledge_graph', to: 'people/knowledge_graph_search#new'
      post 'search/knowledge_graph', to: 'people/knowledge_graph_search#create'
    end
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
            get 'search/tmdb', to: 'people/tmdb_search#new'
            post 'search/tmdb', to: 'people/tmdb_search#create'
            get 'search/knowledge_graph', to: 'people/knowledge_graph_search#new'
            post 'search/knowledge_graph', to: 'people/knowledge_graph_search#create'
          end
        end

        resources :media, only: [:index, :create, :destroy] do
          collection do
            get 'search/tmdb', to: 'media/tmdb_search#new'
            post 'search/tmdb', to: 'media/tmdb_search#create'
            get 'search/unsplash', to: 'media/unsplash_search#new'
            post 'search/unsplash', to: 'media/unsplash_search#create'
            get 'search/artsy', to: 'media/artsy_search#new'
            post 'search/artsy', to: 'media/artsy_search#create'
            get 'search/giphy', to: 'media/giphy_search#new'
            post 'search/giphy', to: 'media/giphy_search#create'
          end
        end

        # Add lyrics routes following the same pattern
        resources :lyrics, only: [:index, :create, :destroy, :show] do
          collection do
            get 'search/genius', to: 'lyrics/genius_search#new'
            post 'search/genius', to: 'lyrics/genius_search#create'
          end
        end

        # Add poems routes following the same pattern
        resources :poems, only: [:index, :create, :destroy] do
          collection do
            get 'search/poetrydb', to: 'poems/poetry_db_search#new'
            post 'search/poetrydb', to: 'poems/poetry_db_search#create'
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

  resources :bots do
    resources :bot_influences, only: [:new, :create, :destroy]
  end

  # Remove these duplicate routes
  # concern :has_poems do
  #   resources :poems do
  #     collection do
  #       get :search
  #       post :search, action: :create_search
  #     end
  #   end
  # end

  # namespace :topics do
  #   resources :concepts, concerns: [:has_poems]
  #   resources :places, concerns: [:has_poems]
  #   resources :events, concerns: [:has_poems]
  #   resources :things, concerns: [:has_poems]
  #   resources :actions, concerns: [:has_poems]
  #   resources :other, concerns: [:has_poems]
  # end
end
