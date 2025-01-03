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

  # STI routes with nested quotes
  %w[people places concepts things events actions others].each do |type|
    resources type, controller: 'topics', type: type.singularize.classify do
      scope module: :topics do
        resources :quotes, only: [:index, :create] do
          collection do
            get 'search/wikiquotes', to: 'quotes/search#new'
            post 'search/wikiquotes', to: 'quotes/search#create'
          end
        end
      end
    end
  end
end
