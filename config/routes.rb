Rails.application.routes.draw do
  # Mount Mission Control Jobs (authentication handled by initializer)
  mount MissionControl::Jobs::Engine => "/mission_control"

  get "up" => "rails/health#show", :as => :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", :as => :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", :as => :pwa_manifest

  root to: "pages#show", defaults: {slug: "/"}
  get "guides", to: "guides#index"
  get "guides/*path", to: "guides#show", as: :guide
  get "safety_standards", to: "safety_standards#index"
  post "safety_standards", to: "safety_standards#index"
  get "search", to: "search#index"

  get "register", to: "users#new"
  post "register", to: "users#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "passkey_login", to: "sessions#passkey", defaults: {format: :json}
  post "passkey_callback", to: "sessions#passkey_callback"

  # Credentials (passkeys)
  resources :credentials, only: [:create, :destroy] do
    post :callback, on: :collection
  end

  # Users management (full CRUD)
  resources :users do
    member do
      get "change_password"
      patch "update_password"
      get "change_settings"
      patch "update_settings"
      post "impersonate"
      post "verify_rpii"
      post "add_seeds"
      delete "delete_seeds"
      post "activate"
      patch "deactivate"
      delete "logout_everywhere_else"
    end
  end

  # Inspections
  resources :inspections, except: [:new] do
    member do
      get "select_unit"
      patch "update_unit"
      patch "complete"
      patch "mark_draft"
      get "unified_edit"
      patch "unified_update"
      get "log"
    end

    Inspection::ALL_ASSESSMENT_TYPES.each_key do |assessment_type|
      resource assessment_type, only: [:update]
    end
  end

  # Units
  resources :units do
    member do
      get "unified_edit"
      patch "unified_update"
      get "log"
    end
  end

  # Create unit from inspection
  get "inspections/:id/new_unit",
    to: "units#new_from_inspection",
    as: "new_unit_from_inspection"
  post "inspections/:id/create_unit",
    to: "units#create_from_inspection",
    as: "create_unit_from_inspection"

  # Inspector Companies
  resources :inspector_companies, except: [:destroy]

  # Admin
  get "admin", to: "admin#index"
  get "admin/releases", to: "admin#releases", as: :admin_releases

  # Backups
  resources :backups, only: [:index] do
    collection do
      get "download"
    end
  end

  # Pages (CMS)
  resources :pages, except: [:show]
  get "pages/:slug",
    to: "pages#show",
    as: :page_by_slug,
    constraints: {slug: /[^\/]+/}

  # Handle error pages when exceptions_app is configured
  match "/404", to: "application#not_found", via: :all
end
