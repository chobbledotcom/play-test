Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", :as => :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", :as => :pwa_manifest

  root "home#index"
  get "about", to: "home#about"
  get "safety_standards", to: "safety_standards#index"
  post "safety_standards", to: "safety_standards#index"

  get "signup", to: "users#new"
  post "signup", to: "users#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Users management (full CRUD)
  resources :users do
    member do
      get "change_password"
      patch "update_password"
      get "change_settings"
      patch "update_settings"
      post "impersonate"
      post "verify_rpii"
    end
  end

  # Inspections
  resources :inspections, except: [:new] do
    member do
      patch "replace_dimensions"
      get "select_unit"
      patch "update_unit"
      patch "complete"
      patch "mark_draft"
    end
  end

  # Units
  resources :units

  # Create unit from inspection
  get "inspections/:id/new_unit", to: "units#new_from_inspection", as: "new_unit_from_inspection"
  post "inspections/:id/create_unit", to: "units#create_from_inspection", as: "create_unit_from_inspection"

  # Inspector Companies
  resources :inspector_companies, except: [:destroy]
end
