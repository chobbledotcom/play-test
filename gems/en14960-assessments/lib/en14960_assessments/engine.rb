# typed: false
# frozen_string_literal: true

module En14960Assessments
  class Engine < ::Rails::Engine
    isolate_namespace En14960Assessments

    # Ensure the gem is loaded when Rails boots
    config.eager_load_namespaces << En14960Assessments::Engine

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Load locale files
    locale_path = Engine.root.join("config", "locales", "**", "*.yml")
    config.i18n.load_path += Dir[locale_path]

    # Autoload paths
    config.autoload_paths << Engine.root.join("app", "models", "concerns")
    config.autoload_paths << Engine.root.join("app", "controllers", "concerns")
    config.autoload_paths << Engine.root.join("app", "services")

    initializer "en14960_assessments.assets" do |app|
      assets = Engine.root.join("app", "assets")
      app.config.assets.paths << assets.join("stylesheets")
      app.config.assets.paths << Engine.root.join("app", "javascript")
      app.config.assets.paths << assets.join("images")
    end

    initializer "en14960_assessments.migrations" do |app|
      unless app.root.to_s.match?(root.to_s)
        migrations = config.paths["db/migrate"].expanded
        app.config.paths["db/migrate"].concat(migrations)
      end
    end

    # Include helpers in host app
    initializer "en14960_assessments.helpers" do
      ActiveSupport.on_load(:action_controller) do
        helper En14960Assessments::Engine.helpers
      end
    end
  end
end
