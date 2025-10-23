# == Route Map
#
#                            Prefix Verb   URI Pattern                                                                                       Controller#Action
#                rails_health_check GET    /up(.:format)                                                                                     rails/health#show
#                              root GET    /                                                                                                 pages#show {slug: "/"}
#                            guides GET    /guides(.:format)                                                                                 guides#index
#                             guide GET    /guides/*path(.:format)                                                                           guides#show
#                  safety_standards GET    /safety_standards(.:format)                                                                       safety_standards#index
#                                   POST   /safety_standards(.:format)                                                                       safety_standards#index
#                            search GET    /search(.:format)                                                                                 search#index
#                          register GET    /register(.:format)                                                                               users#new
#                                   POST   /register(.:format)                                                                               users#create
#                             login GET    /login(.:format)                                                                                  sessions#new
#                                   POST   /login(.:format)                                                                                  sessions#create
#                            logout DELETE /logout(.:format)                                                                                 sessions#destroy
#                     passkey_login GET    /passkey_login(.:format)                                                                          sessions#passkey {format: :json}
#                  passkey_callback POST   /passkey_callback(.:format)                                                                       sessions#passkey_callback
#              callback_credentials POST   /credentials/callback(.:format)                                                                   credentials#callback
#                       credentials POST   /credentials(.:format)                                                                            credentials#create
#                        credential DELETE /credentials/:id(.:format)                                                                        credentials#destroy
#              change_password_user GET    /users/:id/change_password(.:format)                                                              users#change_password
#              update_password_user PATCH  /users/:id/update_password(.:format)                                                              users#update_password
#              change_settings_user GET    /users/:id/change_settings(.:format)                                                              users#change_settings
#              update_settings_user PATCH  /users/:id/update_settings(.:format)                                                              users#update_settings
#                  impersonate_user POST   /users/:id/impersonate(.:format)                                                                  users#impersonate
#           stop_impersonating_user POST   /users/:id/stop_impersonating(.:format)                                                           users#stop_impersonating
#                  verify_rpii_user POST   /users/:id/verify_rpii(.:format)                                                                  users#verify_rpii
#                    add_seeds_user POST   /users/:id/add_seeds(.:format)                                                                    users#add_seeds
#                 delete_seeds_user DELETE /users/:id/delete_seeds(.:format)                                                                 users#delete_seeds
#                     activate_user POST   /users/:id/activate(.:format)                                                                     users#activate
#                   deactivate_user PATCH  /users/:id/deactivate(.:format)                                                                   users#deactivate
#       logout_everywhere_else_user DELETE /users/:id/logout_everywhere_else(.:format)                                                       users#logout_everywhere_else
#                             users GET    /users(.:format)                                                                                  users#index
#                                   POST   /users(.:format)                                                                                  users#create
#                          new_user GET    /users/new(.:format)                                                                              users#new
#                         edit_user GET    /users/:id/edit(.:format)                                                                         users#edit
#                              user GET    /users/:id(.:format)                                                                              users#show
#                                   PATCH  /users/:id(.:format)                                                                              users#update
#                                   PUT    /users/:id(.:format)                                                                              users#update
#                                   DELETE /users/:id(.:format)                                                                              users#destroy
#            select_unit_inspection GET    /inspections/:id/select_unit(.:format)                                                            inspections#select_unit
#            update_unit_inspection PATCH  /inspections/:id/update_unit(.:format)                                                            inspections#update_unit
#               complete_inspection PATCH  /inspections/:id/complete(.:format)                                                               inspections#complete
#             mark_draft_inspection PATCH  /inspections/:id/mark_draft(.:format)                                                             inspections#mark_draft
#           unified_edit_inspection GET    /inspections/:id/unified_edit(.:format)                                                           inspections#unified_edit
#         unified_update_inspection PATCH  /inspections/:id/unified_update(.:format)                                                         inspections#unified_update
#                    log_inspection GET    /inspections/:id/log(.:format)                                                                    inspections#log
# inspection_user_height_assessment PATCH  /inspections/:inspection_id/user_height_assessment(.:format)                                      user_height_assessments#update
#                                   PUT    /inspections/:inspection_id/user_height_assessment(.:format)                                      user_height_assessments#update
#       inspection_slide_assessment PATCH  /inspections/:inspection_id/slide_assessment(.:format)                                            slide_assessments#update
#                                   PUT    /inspections/:inspection_id/slide_assessment(.:format)                                            slide_assessments#update
#   inspection_structure_assessment PATCH  /inspections/:inspection_id/structure_assessment(.:format)                                        structure_assessments#update
#                                   PUT    /inspections/:inspection_id/structure_assessment(.:format)                                        structure_assessments#update
#   inspection_anchorage_assessment PATCH  /inspections/:inspection_id/anchorage_assessment(.:format)                                        anchorage_assessments#update
#                                   PUT    /inspections/:inspection_id/anchorage_assessment(.:format)                                        anchorage_assessments#update
#   inspection_materials_assessment PATCH  /inspections/:inspection_id/materials_assessment(.:format)                                        materials_assessments#update
#                                   PUT    /inspections/:inspection_id/materials_assessment(.:format)                                        materials_assessments#update
#    inspection_enclosed_assessment PATCH  /inspections/:inspection_id/enclosed_assessment(.:format)                                         enclosed_assessments#update
#                                   PUT    /inspections/:inspection_id/enclosed_assessment(.:format)                                         enclosed_assessments#update
#         inspection_fan_assessment PATCH  /inspections/:inspection_id/fan_assessment(.:format)                                              fan_assessments#update
#                                   PUT    /inspections/:inspection_id/fan_assessment(.:format)                                              fan_assessments#update
#                       inspections GET    /inspections(.:format)                                                                            inspections#index
#                                   POST   /inspections(.:format)                                                                            inspections#create
#                   edit_inspection GET    /inspections/:id/edit(.:format)                                                                   inspections#edit
#                        inspection GET    /inspections/:id(.:format)                                                                        inspections#show
#                                   PATCH  /inspections/:id(.:format)                                                                        inspections#update
#                                   PUT    /inspections/:id(.:format)                                                                        inspections#update
#                                   DELETE /inspections/:id(.:format)                                                                        inspections#destroy
#                         all_units GET    /units/all(.:format)                                                                              units#all
#                 unified_edit_unit GET    /units/:id/unified_edit(.:format)                                                                 units#unified_edit
#               unified_update_unit PATCH  /units/:id/unified_update(.:format)                                                               units#unified_update
#                          log_unit GET    /units/:id/log(.:format)                                                                          units#log
#                             units GET    /units(.:format)                                                                                  units#index
#                                   POST   /units(.:format)                                                                                  units#create
#                          new_unit GET    /units/new(.:format)                                                                              units#new
#                         edit_unit GET    /units/:id/edit(.:format)                                                                         units#edit
#                              unit GET    /units/:id(.:format)                                                                              units#show
#                                   PATCH  /units/:id(.:format)                                                                              units#update
#                                   PUT    /units/:id(.:format)                                                                              units#update
#                                   DELETE /units/:id(.:format)                                                                              units#destroy
#          new_unit_from_inspection GET    /inspections/:id/new_unit(.:format)                                                               units#new_from_inspection
#       create_unit_from_inspection POST   /inspections/:id/create_unit(.:format)                                                            units#create_from_inspection
#               inspector_companies GET    /inspector_companies(.:format)                                                                    inspector_companies#index
#                                   POST   /inspector_companies(.:format)                                                                    inspector_companies#create
#             new_inspector_company GET    /inspector_companies/new(.:format)                                                                inspector_companies#new
#            edit_inspector_company GET    /inspector_companies/:id/edit(.:format)                                                           inspector_companies#edit
#                 inspector_company GET    /inspector_companies/:id(.:format)                                                                inspector_companies#show
#                                   PATCH  /inspector_companies/:id(.:format)                                                                inspector_companies#update
#                                   PUT    /inspector_companies/:id(.:format)                                                                inspector_companies#update
#                             admin GET    /admin(.:format)                                                                                  admin#index
#                    admin_releases GET    /admin/releases(.:format)                                                                         admin#releases
#                       admin_files GET    /admin/files(.:format)                                                                            admin#files
#              search_badge_batches GET    /badge_batches/search(.:format)                                                                   badge_batches#search
#                     badge_batches GET    /badge_batches(.:format)                                                                          badge_batches#index
#                                   POST   /badge_batches(.:format)                                                                          badge_batches#create
#                   new_badge_batch GET    /badge_batches/new(.:format)                                                                      badge_batches#new
#                  edit_badge_batch GET    /badge_batches/:id/edit(.:format)                                                                 badge_batches#edit
#                       badge_batch GET    /badge_batches/:id(.:format)                                                                      badge_batches#show
#                                   PATCH  /badge_batches/:id(.:format)                                                                      badge_batches#update
#                                   PUT    /badge_batches/:id(.:format)                                                                      badge_batches#update
#                        edit_badge GET    /badges/:id/edit(.:format)                                                                        badges#edit
#                             badge GET    /badges/:id(.:format)                                                                             badges#show
#                                   PATCH  /badges/:id(.:format)                                                                             badges#update
#                                   PUT    /badges/:id(.:format)                                                                             badges#update
#                  download_backups GET    /backups/download(.:format)                                                                       backups#download
#                           backups GET    /backups(.:format)                                                                                backups#index
#                             pages GET    /pages(.:format)                                                                                  pages#index
#                                   POST   /pages(.:format)                                                                                  pages#create
#                          new_page GET    /pages/new(.:format)                                                                              pages#new
#                         edit_page GET    /pages/:id/edit(.:format)                                                                         pages#edit
#                              page PATCH  /pages/:id(.:format)                                                                              pages#update
#                                   PUT    /pages/:id(.:format)                                                                              pages#update
#                                   DELETE /pages/:id(.:format)                                                                              pages#destroy
#                      page_by_slug GET    /pages/:slug(.:format)                                                                            pages#show {slug: /[^\/]+/}
#                                          /404(.:format)                                                                                    errors#not_found
#                                          /500(.:format)                                                                                    errors#internal_server_error
#  turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                             turbo/native/navigation#recede
#  turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                             turbo/native/navigation#resume
# turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                            turbo/native/navigation#refresh
#                rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#          rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                   GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#         rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#   rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                   GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#         update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#              rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create

# typed: false

Rails.application.routes.draw do
  # Mount Mission Control Jobs (authentication handled by initializer)
  # Only mount if available (not in test environment)
  if defined?(MissionControl::Jobs::Engine)
    mount MissionControl::Jobs::Engine => "/mission_control"
  end

  get "up" => "rails/health#show", :as => :rails_health_check

  get "favicon.ico", to: redirect("icon.svg")

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
  resources :credentials, only: %i[create destroy] do
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
      post "stop_impersonating"
      post "verify_rpii"
      post "add_seeds"
      delete "delete_seeds"
      post "activate"
      patch "deactivate"
      delete "logout_everywhere_else"
    end
  end

  # Inspections
  match "new_inspection_from_unit", to: "inspections#new_from_unit", as: "new_inspection_from_unit", via: [:get, :post]
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
    collection do
      get "all"
    end
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
  get "admin/files", to: "admin#files", as: :admin_files
  resources :admin_text_replacements, only: %i[index new create edit update destroy]

  # Badges (admin-only)
  resources :badge_batches, only: %i[index new create edit update] do
    member do
      get :export
    end
    collection do
      get :search, path: "search", as: :search
    end
  end
  resources :badges, only: %i[edit update]

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
    constraints: {slug: %r{[^/]+}}

  # Handle error pages when exceptions_app is configured
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
