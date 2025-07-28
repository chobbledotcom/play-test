require_relative "lib/chobble/forms/version"

Gem::Specification.new do |spec|
  spec.name = "chobble-forms"
  spec.version = Chobble::Forms::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your@email.com"]

  spec.summary = "Semantic Rails forms with strict i18n"
  spec.description = "A Rails engine for semantic HTML forms with enforced internationalization"
  spec.homepage = "https://github.com/yourusername/chobble-forms"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["{app,config,lib}/**/*", "README.md"]

  spec.add_dependency "rails", ">= 7.0.0"

  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "capybara", "~> 3.0"
end
