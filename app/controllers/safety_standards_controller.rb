class SafetyStandardsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token, only: [:index]

  CALCULATION_TYPES = %w[anchors user_capacity slide_runout wall_height].freeze

  def index
    @calculation_metadata = SafetyStandard.calculation_metadata

    if post_request_with_calculation?
      handle_calculation_post
    else
      handle_calculation_get
    end
  end

  private

  def post_request_with_calculation?
    request.post? && params[:calculation].present?
  end

  def handle_calculation_post
    calculate_safety_standard
    respond_to do |format|
      format.turbo_stream
      format.json { render json: build_json_response }
      format.html { redirect_with_calculation_params }
    end
  end

  def handle_calculation_get
    calculate_safety_standard if params[:calculation].present?
    respond_to do |format|
      format.html
    end
  end

  def redirect_with_calculation_params
    redirect_to safety_standards_path(calculation: params[:calculation].to_unsafe_h)
  end

  def calculate_safety_standard
    type = params[:calculation][:type]
    send("calculate_#{type}") if CALCULATION_TYPES.include?(type)
  end

  def calculate_anchors
    dimensions = extract_dimensions(:length, :width, :height)

    if dimensions.values.all?(&:positive?)
      @anchor_result = SafetyStandard.build_anchor_result(**dimensions)
    else
      set_error(:anchor, :invalid_dimensions)
    end
  end

  def calculate_user_capacity
    dimensions = extract_dimensions(:length, :width)
    adjustment = param_to_float(:negative_adjustment)

    if dimensions.values.all?(&:positive?)
      @capacity_result = build_capacity_result(**dimensions, negative_adjustment: adjustment)
    else
      set_error(:capacity, :invalid_dimensions)
    end
  end

  def calculate_slide_runout
    height = param_to_float(:platform_height)

    if height.positive?
      @runout_result = build_runout_result(height)
    else
      set_error(:runout, :invalid_height)
    end
  end

  def calculate_wall_height
    height = param_to_float(:user_height)

    if height.positive?
      @wall_height_result = build_wall_height_result(height)
    else
      set_error(:wall_height, :invalid_height)
    end
  end

  def extract_dimensions(*keys)
    keys.index_with { |key| param_to_float(key) }
  end

  def param_to_float(key)
    params[:calculation][key].to_f
  end

  def set_error(type, error_key)
    instance_variable_set("@#{type}_error", t("safety_standards.errors.#{error_key}"))
  end

  def build_capacity_result(length:, width:, negative_adjustment:)
    area = length * width
    usable_area = area - negative_adjustment
    {
      length: length,
      width: width,
      area: area,
      negative_adjustment: negative_adjustment,
      usable_area: usable_area,
      capacities: SafetyStandard.calculate_user_capacity(length, width, negative_adjustment)
    }
  end

  def build_runout_result(platform_height)
    required_runout = SafetyStandard.calculate_required_runout(platform_height)
    {
      platform_height: platform_height,
      required_runout: required_runout,
      calculation: build_runout_calculation_text(platform_height, required_runout)
    }
  end

  def build_runout_calculation_text(platform_height, required_runout)
    half_height = platform_height * 0.5
    "50% of #{platform_height}m = #{half_height}m, minimum 0.3m = #{required_runout}m"
  end

  def build_wall_height_result(user_height)
    {
      user_height: user_height,
      requirement: wall_height_requirement_text(user_height),
      requires_roof: SafetyStandard.requires_permanent_roof?(user_height)
    }
  end

  def wall_height_requirement_text(user_height)
    thresholds = SafetyStandard::SLIDE_HEIGHT_THRESHOLDS

    case user_height
    when 0..thresholds[:no_walls_required]
      "No containing walls required"
    when thresholds[:no_walls_required]..thresholds[:basic_walls]
      "Walls must be at least #{user_height}m (equal to user height)"
    when thresholds[:basic_walls]..thresholds[:enhanced_walls]
      wall_height = enhanced_wall_height(user_height)
      "Walls must be at least #{wall_height}m (1.25× user height)"
    when thresholds[:enhanced_walls]..thresholds[:max_safe_height]
      wall_height = enhanced_wall_height(user_height)
      "Walls must be at least #{wall_height}m + permanent roof required"
    else
      "Exceeds safe height limits (>#{thresholds[:max_safe_height]}m)"
    end
  end

  def enhanced_wall_height(user_height)
    (user_height * 1.25).round(2)
  end

  def build_json_response
    type = params[:calculation][:type]

    unless CALCULATION_TYPES.include?(type)
      return {
        passed: false,
        status: "Invalid calculation type: #{type || "none provided"}",
        result: nil
      }
    end

    build_typed_json_response(type)
  rescue => e
    {
      passed: false,
      status: "Calculation failed: #{e.message}",
      result: nil
    }
  end

  def build_typed_json_response(type)
    # Ensure calculation is performed
    calculate_safety_standard

    result_var = case type
    when "anchors" then "@anchor_result"
    when "user_capacity" then "@capacity_result"
    when "slide_runout" then "@runout_result"
    when "wall_height" then "@wall_height_result"
    end

    error_var = case type
    when "anchors" then "@anchor_error"
    when "user_capacity" then "@capacity_error"
    when "slide_runout" then "@runout_error"
    when "wall_height" then "@wall_height_error"
    end

    result = instance_variable_get(result_var)
    error = instance_variable_get(error_var)

    if result
      {
        passed: true,
        status: "Calculation completed successfully",
        result: result
      }
    else
      {
        passed: false,
        status: error || "Calculation failed with unknown error",
        result: nil
      }
    end
  end
end
