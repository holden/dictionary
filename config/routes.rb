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
  
  # STI routes
  resources :people, controller: 'topics', type: 'Person'
  resources :places, controller: 'topics', type: 'Place'
  resources :concepts, controller: 'topics', type: 'Concept'
  resources :things, controller: 'topics', type: 'Thing'
  resources :events, controller: 'topics', type: 'Event'
  resources :actions, controller: 'topics', type: 'Action'
  resources :others, controller: 'topics', type: 'Other'

  # Redirect unauthenticated users
  get 'admin', to: redirect('/sign_in')
end
