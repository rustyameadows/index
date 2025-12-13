Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "projects#index"

  resources :users, only: %i[new create]
  resource :session, only: %i[new create destroy]

  resources :projects, only: %i[index show create new] do
    resources :uploads, only: %i[create show] do
      post :enhance, on: :member
      get :download, on: :member
    end
    resources :entities do
      resources :entity_uploads, only: %i[create destroy]
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
