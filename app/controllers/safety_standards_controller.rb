# typed: strict

class SafetyStandardsController < ApplicationController
  extend T::Sig

  skip_before_action :require_login
  skip_before_action :verify_authenticity_token, only: [:index]

  CALCULATION_TYPES = T.let(%w[anchors slide_runout wall_height user_capacity].freeze, T::Array[String])

  API_EXAMPLE_PARAMS = T.let({
    anchors: {
      type: "anchors",
      length: 5.0,
      width: 5.0,
      height: 3.0
    },
    slide_runout: {
      type: "slide_runout",
      platform_height: 2.5
    },
    wall_height: {
      type: "wall_height",
      platform_height: 2.0,
      user_height: 1.5
    },
    user_capacity: {
      type: "user_capacity",
      length: 10.0,
      width: 8.0,
      negative_adjustment_area: 15.0,
      max_user_height: 1.5
    }
  }.freeze, T::Hash[Symbol, T::Hash[Symbol, T.untyped]])

  API_EXAMPLE_RESPONSES = T.let({
    anchors: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        value: 8,
        value_suffix: "",
        breakdown: [
          ["Front/back area", "5.0m (W) × 3.0m (H) = 15.0m²"],
          ["Sides area", "5.0m (L) × 3.0m (H) = 15.0m²"],
          ["Front & back anchor counts", "((15.0 × 114.0 * 1.5) ÷ 1600.0 = 2"],
          ["Left & right anchor counts", "((15.0 × 114.0 * 1.5) ÷ 1600.0 = 2"],
          ["Calculated total anchors", "(2 + 2) × 2 = 8"]
        ]
      }
    },
    slide_runout: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        value: 1.25,
        value_suffix: "m",
        breakdown: [
          ["50% calculation", "2.5m × 0.5 = 1.25m"],
          ["Minimum requirement", "0.3m (300mm)"],
          ["Base runout", "Maximum of 1.25m and 0.3m = 1.25m"]
        ]
      }
    },
    wall_height: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        value: 1.5,
        value_suffix: "m",
        breakdown: [
          ["Height range", "0.6m - 3.0m"],
          ["Calculation", "1.5m (user height)"]
        ]
      }
    },
    user_capacity: {
      passed: true,
      status: "Calculation completed successfully",
      result: {
        length: 10.0,
        width: 8.0,
        area: 80.0,
        negative_adjustment_area: 15.0,
        usable_area: 65.0,
        max_user_height: 1.5,
        capacities: {
          users_1000mm: 65,
          users_1200mm: 48,
          users_1500mm: 39,
          users_1800mm: 0
        },
        breakdown: [
          ["Total area", "10m × 8m = 80m²"],
          ["Obstacles/adjustments", "- 15m²"],
          ["Usable area", "65m²"],
          ["Capacity calculations", "Based on usable area"],
          ["1m users", "65 ÷ 1 = 65 users"],
          ["1.2m users", "65 ÷ 1.3 = 48 users"],
          ["1.5m users", "65 ÷ 1.7 = 39 users"],
          ["1.8m users", "Not allowed (exceeds height limit)"]
        ]
      }
    }
  }.freeze, T::Hash[Symbol, T::Hash[Symbol, T.untyped]])

  sig { void }
  def index
    @calculation_metadata = calculation_metadata

    if post_request_with_calculation?
      handle_calculation_post
    else
      handle_calculation_get
    end
  end

  private

  sig { returns(T::Boolean) }
  def post_request_with_calculation?
    request.post? && params[:calculation].present?
  end

  sig { void }
  def handle_calculation_post
    type = params[:calculation][:type]
    calculate_safety_standard if CALCULATION_TYPES.include?(type)

    respond_to do |format|
      format.turbo_stream
      format.json { render json: build_json_response }
      format.html { redirect_with_calculation_params }
    end
  end

  sig { void }
  def handle_calculation_get
    if params[:calculation].present?
      type = params[:calculation][:type]
      calculate_safety_standard if CALCULATION_TYPES.include?(type)
    end

    respond_to do |format|
      format.html
    end
  end

  sig { void }
  def redirect_with_calculation_params
    redirect_to safety_standards_path(
      calculation: params[:calculation].to_unsafe_h
    )
  end

  sig { void }
  def calculate_safety_standard
    type = params[:calculation][:type]

    case type
    when "anchors"
      calculate_anchors
    when "slide_runout"
      calculate_slide_runout
    when "wall_height"
      calculate_wall_height
    when "user_capacity"
      calculate_user_capacity
    end
  end

  sig { void }
  def calculate_anchors
    dimensions = extract_dimensions(:length, :width, :height)

    if dimensions.values.all?(&:positive?)
      @anchors_result = EN14960.calculate_anchors(**dimensions)
    else
      set_error(:anchors, :invalid_dimensions)
    end
  end

  sig { void }
  def calculate_slide_runout
    height = param_to_float(:platform_height)
    has_stop_wall = params[:calculation][:has_stop_wall] == "1"

    if height.positive?
      @slide_runout_result = build_runout_result(height, has_stop_wall)
    else
      set_error(:slide_runout, :invalid_height)
    end
  end

  sig { void }
  def calculate_wall_height
    platform_height = param_to_float(:platform_height)
    user_height = param_to_float(:user_height)

    if platform_height.positive? && user_height.positive?
      @wall_height_result = build_wall_height_result(
        platform_height, user_height
      )
    else
      set_error(:wall_height, :invalid_height)
    end
  end

  sig { void }
  def calculate_user_capacity
    length = param_to_float(:length)
    width = param_to_float(:width)
    max_user_height = param_to_float(:max_user_height)
    max_user_height = nil if max_user_height.zero?
    negative_adjustment_area = param_to_float(:negative_adjustment_area)

    if length.positive? && width.positive?
      @user_capacity_result = EN14960.calculate_user_capacity(
        length, width, max_user_height, negative_adjustment_area
      )
    else
      set_error(:user_capacity, :invalid_dimensions)
    end
  end

  sig { params(keys: Symbol).returns(T::Hash[Symbol, Float]) }
  def extract_dimensions(*keys)
    keys.index_with { |key| param_to_float(key) }
  end

  sig { params(key: Symbol).returns(Float) }
  def param_to_float(key)
    params[:calculation][key].to_f
  end

  sig { params(type: Symbol, error_key: Symbol).void }
  def set_error(type, error_key)
    error_msg = t("safety_standards.errors.#{error_key}")
    instance_variable_set("@#{type}_error", error_msg)
    instance_variable_set("@#{type}_result", nil)
  end

  sig { params(platform_height: Float, has_stop_wall: T::Boolean).returns(T.untyped) }
  def build_runout_result(platform_height, has_stop_wall)
    EN14960.calculate_slide_runout(
      platform_height,
      has_stop_wall: has_stop_wall
    )
  end

  sig { params(platform_height: Float, user_height: Float).returns(T.untyped) }
  def build_wall_height_result(platform_height, user_height)
    # Workaround for EN14960 v0.4.0 bug where it returns Integer 0 instead of Float 0.0
    # when platform_height < 0.6
    begin
      EN14960.calculate_wall_height(platform_height, user_height)
    rescue TypeError => e
      if e.message.include?("got type Integer with value 0")
        # Return the expected response for no walls required
        EN14960::CalculatorResponse.new(
          value: 0.0,
          value_suffix: "m",
          breakdown: [["No walls required", "Platform height < 0.6m"]]
        )
      else
        raise e
      end
    end
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def build_json_response
    type = params[:calculation][:type]
    return invalid_type_response(type) unless CALCULATION_TYPES.include?(type)

    build_typed_json_response(type)
  end

  sig { params(type: T.nilable(String)).returns(T::Hash[Symbol, T.untyped]) }
  def invalid_type_response(type)
    {
      passed: false,
      status: t("safety_standards.api.invalid_calculation_type",
        type: type || t("safety_standards.api.none_provided")),
      result: nil
    }
  end

  sig { params(message: String).returns(T::Hash[Symbol, T.untyped]) }
  def error_response(message)
    {
      passed: false,
      status: t("safety_standards.api.calculation_failed", error: message),
      result: nil
    }
  end

  sig { params(type: String).returns(T::Hash[Symbol, T.untyped]) }
  def build_typed_json_response(type)
    calculate_safety_standard

    result, error = get_calculation_results(type)

    if result
      build_success_response(type, result)
    else
      build_error_response(error)
    end
  end

  sig { params(type: String).returns([T.nilable(T.untyped), T.nilable(String)]) }
  def get_calculation_results(type)
    result_var = "@#{type}_result"
    error_var = "@#{type}_error"

    result = instance_variable_get(result_var)
    error = instance_variable_get(error_var)

    [result, error]
  end

  sig { params(type: String, result: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
  def build_success_response(type, result)
    json_result = if type == "user_capacity"
      build_user_capacity_json(result)
    elsif result.is_a?(EN14960::CalculatorResponse)
      {
        value: result.value,
        value_suffix: result.value_suffix || "",
        breakdown: result.breakdown
      }
    else
      result
    end

    {
      passed: true,
      status: t("safety_standards.api.calculation_success"),
      result: json_result
    }
  end

  sig { params(error: T.nilable(String)).returns(T::Hash[Symbol, T.untyped]) }
  def build_error_response(error)
    {
      passed: false,
      status: error || t("safety_standards.api.unknown_error"),
      result: nil
    }
  end

  sig { params(result: T.untyped).returns(T::Hash[Symbol, T.untyped]) }
  def build_user_capacity_json(result)
    return result unless result.is_a?(EN14960::CalculatorResponse)

    length = param_to_float(:length)
    width = param_to_float(:width)
    max_user_height = param_to_float(:max_user_height)
    max_user_height = nil if max_user_height.zero?
    neg_adj = param_to_float(:negative_adjustment_area)

    {
      length: length,
      width: width,
      area: (length * width).round(2),
      negative_adjustment_area: neg_adj,
      usable_area: [(length * width) - neg_adj, 0].max.round(2),
      max_user_height: max_user_height,
      capacities: result.value,
      breakdown: result.breakdown
    }
  end

  sig { returns(T::Hash[Symbol, T::Hash[Symbol, T.untyped]]) }
  def calculation_metadata
    {
      anchors: anchor_metadata,
      slide_runout: slide_runout_metadata,
      wall_height: wall_height_metadata,
      user_capacity: user_capacity_metadata
    }
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def anchor_metadata
    {
      title: t("safety_standards.metadata.anchor_title"),
      description: t("safety_standards.calculators.anchor.description"),
      method_name: :calculate_required_anchors,
      module_name: EN14960::Calculators::AnchorCalculator,
      example_input: 25.0,
      input_unit: "m²",
      output_unit: "anchors",
      formula_text: t("safety_standards.metadata.anchor_formula"),
      standard_reference: t("safety_standards.metadata.standard_reference")
    }
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def slide_runout_metadata
    {
      title: t("safety_standards.metadata.slide_runout_title"),
      description: t("safety_standards.metadata.slide_runout_description"),
      method_name: :calculate_required_runout,
      additional_methods: [:calculate_runout_value],
      module_name: EN14960::Calculators::SlideCalculator,
      example_input: 2.5,
      input_unit: "m",
      output_unit: "m",
      formula_text: t("safety_standards.metadata.runout_formula"),
      standard_reference: t("safety_standards.metadata.standard_reference")
    }
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def wall_height_metadata
    {
      title: t("safety_standards.metadata.wall_height_title"),
      description: t("safety_standards.metadata.wall_height_description"),
      method_name: :meets_height_requirements?,
      module_name: EN14960::Calculators::SlideCalculator,
      example_input: {platform_height: 2.0, user_height: 1.5},
      input_unit: "m",
      output_unit: t("safety_standards.metadata.requirement_text_unit"),
      formula_text: t("safety_standards.metadata.wall_height_formula"),
      standard_reference: t("safety_standards.metadata.standard_reference")
    }
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def user_capacity_metadata
    {
      title: t("safety_standards.metadata.user_capacity_title"),
      description: t("safety_standards.calculators.user_capacity.description"),
      method_name: :calculate,
      module_name: EN14960::Calculators::UserCapacityCalculator,
      example_input: {length: 10.0, width: 8.0},
      input_unit: "m",
      output_unit: "users",
      formula_text: t("safety_standards.metadata.user_capacity_formula"),
      standard_reference: t("safety_standards.metadata.standard_reference")
    }
  end
end
