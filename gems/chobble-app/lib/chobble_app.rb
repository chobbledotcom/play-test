# frozen_string_literal: true

require_relative "chobble_app/version"
require_relative "chobble_app/engine"
require_relative "chobble_app/i18n_usage_tracker"
require_relative "chobble_app/code_standards_checker"
require_relative "chobble_app/erb_lint_runner"

module ChobbleApp
  class Error < StandardError; end
end
