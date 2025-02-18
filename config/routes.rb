Rails.application.routes.draw do
  match '/auth/:provider/callback' => 'application#authentication_callback',
        via: %i[get post]
  get 'application/login'
  get 'application/logout'
  # match "application/role", via: [:get, :post]

  resources :owners do
    member do
      match :service_area, via: %i[get post]
      post :delete_service_area
    end
    resources :datasets do
      match :test_ticket, via: %i[get post]
      member do
        get :new_wizard
        post :create_step1
        post :create_step2
        post :create_step3
      end
    end
    resources :users, except: [:show]
  end

  get 'system_settings' => 'system_settings#index'
  resources :feature_classes, except: [:show]
  resources :ticket_types, except: [:show]
  resources :feature_statuses, except: [:show]
  resources :accuracy_classes, except: [:show]
  resources :system_configurations, only: [:index, :show, :edit, :update]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'owners#index'
end
