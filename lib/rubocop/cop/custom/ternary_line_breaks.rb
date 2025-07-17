# frozen_string_literal: true

module RuboCop
  module Cop
    module Custom
      # Enforces line breaks after ? and : in ternary operators when
      # line exceeds 80 characters
      #
      # @example
      #   # bad (when line > 80 chars)
      #   result = condition == 2 ? long_true_value : long_false_value
      #
      #   # good
      #   result = condition == 2 ?
      #     long_true_value :
      #     long_false_value
      #
      class TernaryLineBreaks < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = "Break ternary operator across multiple lines " \
              "when line exceeds 80 characters"
        MAX_LINE_LENGTH = 80

        def on_if(node)
          return unless node.ternary?
          return unless line_too_long?(node)

          add_offense(node) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def line_too_long?(node)
          line = processed_source.lines[node.first_line - 1]
          line.length > MAX_LINE_LENGTH
        end

        def autocorrect(corrector, node)
          condition = node.condition
          if_branch = node.if_branch
          else_branch = node.else_branch

          # Get the indentation of the line containing the ternary
          indent = processed_source.lines[node.first_line - 1][/\A\s*/]
          nested_indent = "#{indent}  "

          # Build the corrected version
          corrected = "#{condition.source} ?\n"
          corrected << "#{nested_indent}#{if_branch.source} :\n"
          corrected << "#{nested_indent}#{else_branch.source}"

          corrector.replace(node, corrected)
        end
      end
    end
  end
end
