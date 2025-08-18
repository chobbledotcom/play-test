# typed: strict

# Rails URL helpers for controllers
module Rails
  module Application
    module Routes
      module UrlHelpers
        extend T::Sig
        
        sig { params(args: T.untyped).returns(String) }
        def safety_standards_path(*args); end
        
        sig { params(args: T.untyped).returns(String) }
        def safety_standards_url(*args); end
      end
    end
  end
end

# Include URL helpers in controllers
class ActionController::Base
  include Rails::Application::Routes::UrlHelpers
end