# typed: strong  
# frozen_string_literal: true

# Ensure the controller hierarchy is properly defined for Sorbet
class AbstractController::Base; end
class ActionController::Metal < AbstractController::Base; end
class ActionController::Base < ActionController::Metal; end