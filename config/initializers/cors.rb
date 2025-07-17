Rails.application.config.middleware.use Rack::Cors do
  allow do
    origins "*"
    resource "/units/*", headers: :any, methods: [:head]
    resource "/inspections/*", headers: :any, methods: [:head]
    resource "/units/*.json", headers: :any, methods: [:get]
    resource "/inspections/*.json", headers: :any, methods: [:get]
  end
end
