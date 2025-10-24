# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Prevents checking if classes or modules are defined using `defined?()`
      # This is fragile and can lead to subtle bugs. Instead, use environment
      # variables or configuration flags to determine feature availability.
      #
      # @example
      #   # bad
      #   if defined?(SomeClass)
      #     SomeClass.do_something
      #   end
      #
      #   # bad
      #   DatabaseI18nBackend.reload_cache if defined?(DatabaseI18nBackend)
      #
      #   # good
      #   if Rails.env.production?
      #     SomeClass.do_something
      #   end
      #
      #   # good
      #   if Rails.configuration.feature_enabled
      #     FeatureClass.do_something
      #   end
      #
      class NoClassDefinedChecks < Base
        MSG = "Avoid checking if classes/modules are defined. " \
              "Use environment checks (Rails.env.production?) or " \
              "configuration flags instead."

        # Pattern to detect constant references (classes/modules)
        # Constants start with uppercase letter
        CONSTANT_PATTERN = /\A[A-Z]/.freeze

        def on_defined?(node)
          return unless node.arguments.any?

          argument = node.arguments.first
          return unless checking_constant?(argument)

          # Allow certain safe patterns
          return if allowed_pattern?(argument)

          add_offense(node)
        end

        private

        def checking_constant?(node)
          case node.type
          when :const
            # Single constant like `SomeClass`
            true
          when :send
            # Method call on a constant like `ActiveStorage::Service::S3Service`
            false
          else
            # Check if it's a constant reference by source
            source = node.source
            source.match?(CONSTANT_PATTERN)
          end
        end

        def allowed_pattern?(node)
          source = node.source

          # Allow checking instance/local variables (not classes)
          return true if source.start_with?("@", "@@")
          return true unless source.match?(CONSTANT_PATTERN)

          # Allow specific test-related constants in spec files
          return true if in_spec_file? && test_related_constant?(source)

          # Allow Sorbet type checking constants in RBI files
          return true if processed_source.path.end_with?(".rbi")

          false
        end

        def in_spec_file?
          processed_source.path.include?("/spec/")
        end

        def test_related_constant?(source)
          # Allow checking test frameworks and libraries in tests
          test_constants = %w[
            RSpec
            FactoryBot
            Capybara
            T
            page
          ]

          test_constants.any? { |const| source.start_with?(const) }
        end
      end
    end
  end
end
