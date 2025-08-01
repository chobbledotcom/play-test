Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "/units/*", headers: :any, methods: [:head]
    resource "/inspections/*", headers: :any, methods: [:head]
    resource "/units/*.json", headers: :any, methods: [:get]
    resource "/inspections/*.json", headers: :any, methods: [:get]
    # ActiveStorage routes for Safari compatibility
    resource "/rails/active_storage/*", headers: :any, methods: [:get, :head, :options]
  end
end
