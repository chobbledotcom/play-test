Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", :as => :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", :as => :pwa_manifest

  root "home#index"
  get "about", to: "home#about"

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
    end
  end

  # Inspections
  resources :inspections do
    collection do
      get "search"
      get "overdue"
    end
    member do
      get "certificate"
      get "qr_code"
    end
  end

  # Equipment
  resources :equipment do
    collection do
      get "search"
      get "overdue"
    end
    member do
      get "certificate"
      get "qr_code"
    end
  end

  # Short URL for certificates
  get "c/:id", to: "inspections#certificate", as: "short_certificate"
  get "C/:id", to: "inspections#certificate", as: "short_certificate_uppercase"

  # Short URL for equipment certificates
  get "e/:id", to: "equipment#certificate", as: "short_equipment_certificate"
  get "E/:id", to: "equipment#certificate", as: "short_equipment_certificate_uppercase"
end
