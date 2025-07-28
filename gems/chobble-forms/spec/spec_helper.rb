require "bundler/setup"

# Mock Rails before loading the gem
require "ostruct"

module Rails
  class Engine
    def self.isolate_namespace(mod)
      # no-op for testing
    end

    def self.config
      @config ||= OpenStruct.new(
        to_prepare: ->(&block) {},
        generators: OpenStruct.new
      )
    end

    def self.initializer(name, &block)
      # no-op for testing
    end
  end

  def self.application
    @application ||= OpenStruct.new(
      config: OpenStruct.new
    )
  end

  module VERSION
    STRING = "7.0.0"
  end
end

module ActiveSupport
  def self.on_load(name, &block)
    # no-op for testing
  end
end

class ApplicationController
  def self.helper(mod)
    # no-op for testing
  end
end

require "chobble-forms"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
