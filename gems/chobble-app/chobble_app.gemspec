# frozen_string_literal: true

require_relative "lib/chobble_app/version"

Gem::Specification.new do |spec|
  spec.name = "chobble_app"
  spec.version = ChobbleApp::VERSION
  spec.authors = ["Chobble Team"]
  spec.email = ["team@chobble.com"]

  spec.summary = "Core infrastructure for Chobble applications"
  spec.description = "Provides user management, authentication, and shared functionality for Chobble apps"
  spec.homepage = "https://github.com/chobble/chobble-app"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "rails", ">= 7.1.0"
  spec.add_dependency "bcrypt", "~> 3.1"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "image_processing", "~> 1.12"

  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "factory_bot_rails", "~> 6.4"
  spec.add_development_dependency "standard", "~> 1.35"
end