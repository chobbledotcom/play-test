# typed: false
# frozen_string_literal: true

require "rails_helper"
require "rubocop"
require "rubocop/rspec/support"

# Load the custom cop using Rails.root
require Rails.root.join("lib/rubocop/cop/custom/one_line_methods")

RSpec.describe RuboCop::Cop::Custom::OneLineMethods, type: :rubocop do
  include RuboCop::RSpec::ExpectOffense

  let(:config) { RuboCop::Config.new }
  let(:cop) { described_class.new(config) }

  context "when method is a simple alias with same arguments" do
    it "registers an offense for single argument pass-through" do
      message = "Custom/OneLineMethods: Call the original method directly " \
                "instead of creating an aliasing wrapper method"
      expect_offense(<<~RUBY)
        def fetch_user(id)
        ^^^^^^^^^^^^^^^^^^ #{message}
          get_user(id)
        end
      RUBY
    end

    it "registers an offense for multiple arguments pass-through" do
      message = "Custom/OneLineMethods: Call the original method directly " \
                "instead of creating an aliasing wrapper method"
      expect_offense(<<~RUBY)
        def find_record(type, id)
        ^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
          lookup_record(type, id)
        end
      RUBY
    end

    it "registers an offense for class methods" do
      message = "Custom/OneLineMethods: Call the original method directly " \
                "instead of creating an aliasing wrapper method"
      expect_offense(<<~RUBY)
        def self.fetch_user(id)
        ^^^^^^^^^^^^^^^^^^^^^^^ #{message}
          get_user(id)
        end
      RUBY
    end
  end

  context "when method is not a simple alias" do
    it "does not register offense for methods with different arguments" do
      expect_no_offenses(<<~RUBY)
        def full_name
          format_name(first_name, last_name)
        end
      RUBY
    end

    it "does not register offense for methods without arguments" do
      expect_no_offenses(<<~RUBY)
        def complete?
          incomplete_fields.empty?
        end
      RUBY
    end

    it "does not register offense for methods calling on a receiver" do
      expect_no_offenses(<<~RUBY)
        def user_name
          user.name
        end
      RUBY
    end

    it "does not register offense for comparison operations" do
      expect_no_offenses(<<~RUBY)
        def triggered_by?(check_user)
          user == check_user
        end
      RUBY
    end

    it "does not register offense for calculations" do
      expect_no_offenses(<<~RUBY)
        def total_anchors
          (num_low_anchors || 0) + (num_high_anchors || 0)
        end
      RUBY
    end

    it "does not register offense for transformations" do
      expect_no_offenses(<<~RUBY)
        def column_name_syms
          column_names.map(&:to_sym).sort
        end
      RUBY
    end

    it "does not register offense for multi-line methods" do
      expect_no_offenses(<<~RUBY)
        def some_method(arg)
          result = process(arg)
          result
        end
      RUBY
    end

    # Endless methods are handled differently and won't be parsed as regular
    # methods so they naturally won't trigger this cop
  end

  context "edge cases" do
    it "does not register offense for methods with blocks" do
      expect_no_offenses(<<~RUBY)
        def process_items(items)
          handle_items(items) { |item| item.process }
        end
      RUBY
    end

    it "does not register offense for methods with keyword arguments" do
      expect_no_offenses(<<~RUBY)
        def create_user(name:, email:)
          build_user(name: name, email: email)
        end
      RUBY
    end

    it "does not register offense for methods with splat arguments" do
      expect_no_offenses(<<~RUBY)
        def forward_args(*args)
          process(*args)
        end
      RUBY
    end

    it "does not register offense when arguments are reordered" do
      expect_no_offenses(<<~RUBY)
        def swap_args(a, b)
          process(b, a)
        end
      RUBY
    end

    it "does not register offense when fewer arguments are passed" do
      expect_no_offenses(<<~RUBY)
        def simplified_call(a, b)
          complex_call(a)
        end
      RUBY
    end

    it "does not register offense for delegations without arguments" do
      expect_no_offenses(<<~RUBY)
        def current_user
          fetch_current_user
        end
      RUBY
    end
  end
end
