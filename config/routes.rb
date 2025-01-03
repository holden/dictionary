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
      get 'quotes', to: 'topics/quotes#index'
      post 'quotes', to: 'topics/quotes#create'
    end
  end
end
