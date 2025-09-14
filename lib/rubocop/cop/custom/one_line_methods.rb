# typed: false
# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Detects one-line methods that are simple aliases
      # (passing same arguments through)
      # These should call the original method directly instead
      #
      # @example
      #   # bad - unnecessary wrapper method
      #   def user_name(id)
      #     fetch_user_name(id)
      #   end
      #
      #   # good - just call fetch_user_name directly
      #
      #   # good - performs calculation
      #   def total_anchors
      #     (num_low_anchors || 0) + (num_high_anchors || 0)
      #   end
      #
      #   # good - calls with different arguments
      #   def full_name
      #     format_name(first_name, last_name)
      #   end
      #
      class OneLineMethods < Base
        MSG = "Call the original method directly instead of creating " \
              "an aliasing wrapper method"

        def on_def(node)
          return unless aliasing_method?(node)

          add_offense(node)
        end

        def on_defs(node)
          return unless aliasing_method?(node)

          add_offense(node)
        end

        private

        def aliasing_method?(node)
          body = node.body
          return false unless body
          return false unless body.send_type?
          return false if body.receiver

          method_args = node.arguments
          call_args = body.arguments

          return false unless method_args.size == call_args.size
          return false if method_args.empty?

          arguments_match?(method_args, call_args)
        end

        def arguments_match?(method_args, call_args)
          method_args.zip(call_args).all? do |method_arg, call_arg|
            call_arg.lvar_type? && call_arg.children.first == method_arg.name
          end
        end
      end
    end
  end
end
