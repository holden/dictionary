Rails.application.routes.draw do
  # Authentication routes should be first
  resource :session
  resources :passwords, param: :token

  # Admin routes - place before other routes to ensure proper precedence
  get 'admin', to: 'admin/dashboard#index'
  
  namespace :admin do
    root to: 'dashboard#index'
    resources :events
    resources :orders
    resource :settings, only: [:show, :edit, :update]
  end

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
  
  # STI routes with nested quotes
  %w[people places concepts things events actions others].each do |type|
    resources type, controller: 'topics', type: type.singularize.classify do
      get 'quotes', to: 'topics/quotes#index'
      post 'quotes', to: 'topics/quotes#create'
    end
  end

  # Redirect unauthenticated users
  get 'admin', to: redirect('/sign_in')

  namespace :admin do
    resources :quotes, only: [:index] do
      collection do
        get :search
      end
    end
  end
end
