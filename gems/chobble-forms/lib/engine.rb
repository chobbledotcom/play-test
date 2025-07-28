module ChobbleForms
  class Engine < ::Rails::Engine
    isolate_namespace ChobbleForms

    initializer "chobble_forms.add_view_paths" do |app|
      ActiveSupport.on_load(:action_controller) do
        prepend_view_path ChobbleForms::Engine.root.join("views")
      end
    end

    config.to_prepare do
      ApplicationController.helper(ChobbleForms::Helpers)
    end

    initializer "chobble_forms.view_helpers" do
      ActiveSupport.on_load(:action_view) do
        include ChobbleForms::Helpers
      end
    end
  end
end
