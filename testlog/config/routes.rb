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
  resources :inspections, except: [:new] do
    collection do
      get "search"
      get "overdue"
    end
    member do
      get "report"
      get "qr_code"
    end
  end

  # Units
  resources :units do
    collection do
      get "search"
    end
    member do
      get "report"
      get "qr_code"
    end
  end

  # Inspector Companies
  resources :inspector_companies, except: [:destroy] do
    member do
      patch "archive"
      patch "unarchive"
    end
  end

  # Short URL for reports
  get "r/:id", to: "inspections#report", as: "short_report"
  get "R/:id", to: "inspections#report", as: "short_report_uppercase"

  # Short URL for unit reports
  get "u/:id", to: "units#report", as: "short_unit_report"
  get "U/:id", to: "units#report", as: "short_unit_report_uppercase"
end
