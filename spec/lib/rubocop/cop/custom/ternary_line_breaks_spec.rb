# frozen_string_literal: true

require "rails_helper"
require "rubocop"
require "rubocop/rspec/support"

# Load the custom cop using Rails.root
require Rails.root.join("lib/rubocop/cop/custom/ternary_line_breaks")

RSpec.describe RuboCop::Cop::Custom::TernaryLineBreaks, type: :rubocop do
  include RuboCop::RSpec::ExpectOffense

  let(:config) { RuboCop::Config.new }
  let(:cop) { described_class.new(config) }

  context "when ternary operator is under 80 characters" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        result = condition ? true_value : false_value
      RUBY
    end

    it "does not register an offense for short ternary with method calls" do
      expect_no_offenses(<<~RUBY)
        status = user.active? ? "Active" : "Inactive"
      RUBY
    end
  end

  context "when ternary operator exceeds 80 characters" do
    it "registers an offense and corrects simple case" do
      expect_offense(<<~RUBY)
        result = very_long_condition_that_exceeds_limit ? very_long_true_value : very_long_false_value
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/TernaryLineBreaks: Break ternary operator across multiple lines when line exceeds 80 characters
      RUBY

      expect_correction(<<~RUBY)
        result = very_long_condition_that_exceeds_limit ?
          very_long_true_value :
          very_long_false_value
      RUBY
    end

    it "registers an offense and corrects with method chains" do
      expect_offense(<<~RUBY)
        message = user.company.active? ? "Company is active and operational" : "Company is inactive"
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/TernaryLineBreaks: Break ternary operator across multiple lines when line exceeds 80 characters
      RUBY

      expect_correction(<<~RUBY)
        message = user.company.active? ?
          "Company is active and operational" :
          "Company is inactive"
      RUBY
    end

    it "preserves indentation when correcting" do
      expect_offense(<<~RUBY)
        def some_method
          result = condition_check ? "This is a very long true value" : "This is a very long false value"
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/TernaryLineBreaks: Break ternary operator across multiple lines when line exceeds 80 characters
        end
      RUBY

      expect_correction(<<~RUBY)
        def some_method
          result = condition_check ?
            "This is a very long true value" :
            "This is a very long false value"
        end
      RUBY
    end

    it "handles nested method calls in conditions" do
      expect_offense(<<~RUBY)
        has_permission = user.admin? || user.moderator? ? grant_full_access : grant_limited_access
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/TernaryLineBreaks: Break ternary operator across multiple lines when line exceeds 80 characters
      RUBY

      expect_correction(<<~RUBY)
        has_permission = user.admin? || user.moderator? ?
          grant_full_access :
          grant_limited_access
      RUBY
    end
  end

  context "when ternary is already multi-line" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        result = condition ?
          true_value :
          false_value
      RUBY
    end
  end

  context "edge cases" do
    it "handles ternary with parentheses" do
      expect_offense(<<~RUBY)
        value = (some_long_condition && another_condition) ? long_true_result : long_false_result
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/TernaryLineBreaks: Break ternary operator across multiple lines when line exceeds 80 characters
      RUBY

      expect_correction(<<~RUBY)
        value = (some_long_condition && another_condition) ?
          long_true_result :
          long_false_result
      RUBY
    end

    it "handles ternary with complex expressions" do
      expect_offense(<<~RUBY)
        total = items.count > 0 ? items.map(&:price).sum * tax_rate : default_minimum_charge
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/TernaryLineBreaks: Break ternary operator across multiple lines when line exceeds 80 characters
      RUBY

      expect_correction(<<~RUBY)
        total = items.count > 0 ?
          items.map(&:price).sum * tax_rate :
          default_minimum_charge
      RUBY
    end

    it "does not process if statements that are not ternary" do
      expect_no_offenses(<<~RUBY)
        if very_long_condition_that_would_exceed_eighty_characters_if_it_were_ternary
          do_something
        else
          do_something_else
        end
      RUBY
    end
  end
end
