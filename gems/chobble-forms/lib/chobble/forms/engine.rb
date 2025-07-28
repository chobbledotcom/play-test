module Chobble
  module Forms
    class Engine < ::Rails::Engine
      isolate_namespace Chobble::Forms

      config.to_prepare do
        ApplicationController.helper(Chobble::Forms::Helpers)
      end

      initializer "chobble_forms.view_helpers" do
        ActiveSupport.on_load(:action_view) do
          include Chobble::Forms::Helpers
        end
      end
    end
  end
end
