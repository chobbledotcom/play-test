# typed: strong
# frozen_string_literal: true

# This file provides type signatures for the EN14960 gem's public API.
# It is manually maintained since the gem itself is already typed with Sorbet.

module EN14960
  extend T::Sig

  class Error < StandardError; end

  class CalculatorResponse
    sig { returns(T.untyped) }
    attr_reader :value

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :breakdown

    sig { returns(T::Hash[Symbol, T.untyped]) }
    attr_reader :metadata

    sig { params(value: T.untyped, breakdown: T::Hash[Symbol, T.untyped], metadata: T::Hash[Symbol, T.untyped]).void }
    def initialize(value:, breakdown: {}, metadata: {}); end
  end

  # Public API methods
  sig { params(length: Float, width: Float, height: Float).returns(CalculatorResponse) }
  def self.calculate_anchors(length:, width:, height:); end

  sig { params(platform_height: Float, has_stop_wall: T::Boolean).returns(CalculatorResponse) }
  def self.calculate_slide_runout(platform_height, has_stop_wall: false); end

  sig { params(platform_height: Float, user_height: Float, has_permanent_roof: T.nilable(T::Boolean)).returns(CalculatorResponse) }
  def self.calculate_wall_height(platform_height, user_height, has_permanent_roof = nil); end

  sig { params(age_group: String, platform_height: Float).returns(CalculatorResponse) }
  def self.calculate_user_capacity_values(age_group, platform_height); end

  sig { params(age_group: String, platform_height: Float, user_count: Integer).returns(CalculatorResponse) }
  def self.calculate_user_capacity(age_group, platform_height, user_count); end

  sig { params(material_type: String, section: String).returns(CalculatorResponse) }
  def self.validate_material(material_type, section); end

  sig { params(area_type: String, under_3_area: Float, over_3_area: Float).returns(CalculatorResponse) }
  def self.validate_play_area(area_type, under_3_area, over_3_area); end

  module Calculators
    class AnchorCalculator
      extend T::Sig

      sig { params(length: Float, width: Float, height: Float).returns(CalculatorResponse) }
      def self.calculate(length:, width:, height:); end
    end

    class SlideCalculator
      extend T::Sig

      sig { params(platform_height: Float, has_stop_wall: T::Boolean).returns(CalculatorResponse) }
      def self.calculate_required_runout(platform_height, has_stop_wall: false); end

      sig { params(platform_height: Float, slide_type: String, direction: String).returns(T::Boolean) }
      def self.meets_height_requirements?(platform_height, slide_type, direction); end
    end

    class UserCapacityCalculator
      extend T::Sig

      sig { params(age_group: String, platform_height: Float).returns(CalculatorResponse) }
      def self.calculate_values(age_group, platform_height); end

      sig { params(age_group: String, platform_height: Float, user_count: Integer).returns(CalculatorResponse) }
      def self.calculate(age_group, platform_height, user_count); end
    end
  end

  module Validators
    class MaterialValidator
      extend T::Sig

      sig { params(material_type: String, section: String).returns(CalculatorResponse) }
      def self.validate(material_type, section); end
    end

    class PlayAreaValidator
      extend T::Sig

      sig { params(area_type: String, under_3_area: Float, over_3_area: Float).returns(CalculatorResponse) }
      def self.validate(area_type, under_3_area, over_3_area); end
    end
  end

  module Constants
    # Constants would go here
  end

  module SourceCode
    # Source code references
  end
end