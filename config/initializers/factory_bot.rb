# typed: false
# frozen_string_literal: true

# Load factories from the en14960-assessments gem
if defined?(FactoryBot) && Rails.env.test?
  Rails.application.config.after_initialize do
    # Find the gem's actual installed path
    gem_spec = Gem::Specification.find_by_name("en14960-assessments")
    gem_factories_path = File.join(gem_spec.gem_dir, "spec", "factories")

    # Add to FactoryBot's search paths
    FactoryBot.definition_file_paths << gem_factories_path
    FactoryBot.reload
  end
end
