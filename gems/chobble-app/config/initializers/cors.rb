Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "/units/*", headers: :any, methods: [:head]
    resource "/inspections/*", headers: :any, methods: [:head]
    resource "/units/*.json", headers: :any, methods: [:get]
    resource "/inspections/*.json", headers: :any, methods: [:get]
  end
end
