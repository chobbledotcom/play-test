# frozen_string_literal: true

module ChobbleApp
  class Engine < ::Rails::Engine
    # Don't isolate namespace to allow controllers to be used directly in main app

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    initializer "chobble_app.assets" do |app|
      app.config.assets.paths << root.join("app/assets/stylesheets")
      app.config.assets.paths << root.join("app/assets/javascripts")
      app.config.assets.paths << root.join("app/assets/images")
    end

    initializer "chobble_app.load_app_instance" do |app|
      app.config.to_prepare do
        # Load helpers into the main app
        ApplicationController.helper ChobbleApp::Engine.helpers
      end
    end
  end
end