# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Symbol#to_sym override" do
  describe "#to_sym" do
    context "when called on a Symbol" do
      it "raises an ArgumentError" do
        expect { :test_symbol.to_sym }.to raise_error(
          ArgumentError,
          "Calling to_sym on a Symbol is redundant. The object is already a Symbol: :test_symbol"
        )
      end

      it "includes the symbol name in the error message" do
        expect { :another_symbol.to_sym }.to raise_error(
          ArgumentError,
          /The object is already a Symbol: :another_symbol/
        )
      end
    end

    context "when called on a String" do
      it "still works normally and returns a Symbol" do
        expect("test_string".to_sym).to eq(:test_string)
      end

      it "converts the string to a symbol" do
        result = "hello_world".to_sym
        expect(result).to be_a(Symbol)
        expect(result).to eq(:hello_world)
      end
    end

    context "when called on other objects that respond to to_sym" do
      it "works for integers" do
        # Ruby allows converting integers to symbols via their string representation
        expect(42.to_s.to_sym).to eq(:"42")
      end

      it "works for nil converted to string first" do
        expect(nil.to_s.to_sym).to eq(:"")
      end
    end
  end
end