# frozen_string_literal: true

require_relative "lib/en14960_assessments/version"

Gem::Specification.new do |spec|
  spec.name = "en14960-assessments"
  spec.version = En14960Assessments::VERSION
  spec.authors = ["Chobble.com"]
  spec.email = ["hello@chobble.com"]

  spec.summary = "EN14960 safety assessments for inflatable play equipment"
  spec.description = "A Rails engine providing comprehensive EN14960 safety standard assessments and inspections for bouncy castles and inflatable play equipment"
  spec.homepage = "https://github.com/chobbledotcom/en14960-assessments"
  spec.license = "AGPLv3"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies - based on the main app's requirements
  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "turbo-rails"
  spec.add_dependency "stimulus-rails"
  
  # For PDF generation
  spec.add_dependency "prawn"
  spec.add_dependency "prawn-table"
  
  # For QR code generation
  spec.add_dependency "rqrcode"
  
  # For image processing (Active Storage variants)
  spec.add_dependency "image_processing"
  
  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  
  # Testing framework
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.0"
  spec.add_development_dependency "capybara", "~> 3.0"
  spec.add_development_dependency "cuprite"
  spec.add_development_dependency "rails-controller-testing", "~> 1.0"
  
  # Code coverage
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "simplecov-cobertura"
  
  # Test utilities
  spec.add_development_dependency "pdf-inspector"
  spec.add_development_dependency "parallel_tests"
  spec.add_development_dependency "database_cleaner-active_record"
  spec.add_development_dependency "rspec_junit_formatter"
  
  # Code quality
  spec.add_development_dependency "standard", "~> 1.0"
  spec.add_development_dependency "standard-rails"
  spec.add_development_dependency "erb_lint"
  spec.add_development_dependency "better_html"
  
  # For development database
  spec.add_development_dependency "sqlite3", "~> 1.4"
  
  # N+1 query detection
  spec.add_development_dependency "prosopite"
  spec.add_development_dependency "pg_query"
end
