Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "topics#index"
  resources :topics, only: [:index]
  
  # Add specific routes for each STI type
  resources :people, controller: 'topics', type: 'Person'
  resources :places, controller: 'topics', type: 'Place'
  resources :concepts, controller: 'topics', type: 'Concept'
  resources :things, controller: 'topics', type: 'Thing'
  resources :events, controller: 'topics', type: 'Event'
  resources :actions, controller: 'topics', type: 'Action'
  resources :others, controller: 'topics', type: 'Other'

  resources :topics do
    collection do
      get :search
    end
  end
end
