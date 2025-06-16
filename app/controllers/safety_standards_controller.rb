class SafetyStandardsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token, only: [:index]

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
    calculation_params = params[:calculation].to_unsafe_h
    redirect_to safety_standards_path(calculation: calculation_params)
  end

  def calculate_safety_standard
    calculation_type = params[:calculation][:type]
    case calculation_type
    when "anchors" then calculate_anchors
    when "user_capacity" then calculate_user_capacity
    when "slide_runout" then calculate_slide_runout
    when "wall_height" then calculate_wall_height
    end
  end

  def calculate_anchors
    area = params[:calculation][:area].to_f

    return set_anchor_error unless area.positive?

    @anchor_result = build_anchor_result(area)
  end

  def set_anchor_error
    @anchor_error = t("safety_standards.errors.invalid_area")
  end

  def build_anchor_result(area)
    required_anchors = SafetyStandard.calculate_required_anchors(area)
    {
      area: area,
      required_anchors: required_anchors,
      formula_breakdown: build_anchor_formula(area, required_anchors)
    }
  end

  def build_anchor_formula(area, required_anchors)
    "((#{area}² × 114) ÷ 1600) × 1.5 = #{required_anchors}"
  end

  def calculate_user_capacity
    length = params[:calculation][:length].to_f
    width = params[:calculation][:width].to_f
    negative_adjustment = params[:calculation][:negative_adjustment].to_f

    return set_capacity_error unless valid_dimensions?(length, width)

    @capacity_result = build_capacity_result(length, width, negative_adjustment)
  end

  def valid_dimensions?(length, width)
    length.positive? && width.positive?
  end

  def set_capacity_error
    @capacity_error = t("safety_standards.errors.invalid_dimensions")
  end

  def build_capacity_result(length, width, negative_adjustment)
    area = length * width
    usable_area = area - negative_adjustment
    {
      length: length,
      width: width,
      area: area,
      negative_adjustment: negative_adjustment,
      usable_area: usable_area,
      capacities: SafetyStandard.calculate_user_capacity(length,
        width,
        negative_adjustment)
    }
  end

  def calculate_slide_runout
    platform_height = params[:calculation][:platform_height].to_f

    return set_runout_error unless platform_height.positive?

    @runout_result = build_runout_result(platform_height)
  end

  def set_runout_error
    @runout_error = t("safety_standards.errors.invalid_height")
  end

  def build_runout_result(platform_height)
    required_runout = SafetyStandard.calculate_required_runout(platform_height)
    {
      platform_height: platform_height,
      required_runout: required_runout,
      calculation: build_runout_calculation_text(platform_height,
        required_runout)
    }
  end

  def build_runout_calculation_text(platform_height, required_runout)
    half_height = platform_height * 0.5
    "50% of #{platform_height}m = #{half_height}m, " \
    "minimum 0.3m = #{required_runout}m"
  end

  def calculate_wall_height
    user_height = params[:calculation][:user_height].to_f

    return set_wall_height_error unless user_height.positive?

    @wall_height_result = build_wall_height_result(user_height)
  end

  def set_wall_height_error
    @wall_height_error = t("safety_standards.errors.invalid_height")
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
      enhanced_height = calculate_enhanced_wall_height(user_height)
      "Walls must be at least #{enhanced_height}m (1.25× user height)"
    when thresholds[:enhanced_walls]..thresholds[:max_safe_height]
      enhanced_height = calculate_enhanced_wall_height(user_height)
      "Walls must be at least #{enhanced_height}m + permanent roof required"
    else
      "Exceeds safe height limits (>#{thresholds[:max_safe_height]}m)"
    end
  end

  def calculate_enhanced_wall_height(user_height)
    (user_height * 1.25).round(2)
  end

  def build_json_response
    calculation_type = params[:calculation][:type]
    case calculation_type
    when "anchors" then build_anchor_json_response
    when "user_capacity" then build_capacity_json_response
    when "slide_runout" then build_runout_json_response
    when "wall_height" then build_wall_height_json_response
    else
      {success: false, error: "Invalid calculation type"}
    end
  end

  def build_anchor_json_response
    if @anchor_result
      {success: true, result: @anchor_result}
    else
      {success: false, error: @anchor_error}
    end
  end

  def build_capacity_json_response
    if @capacity_result
      {success: true, result: @capacity_result}
    else
      {success: false, error: @capacity_error}
    end
  end

  def build_runout_json_response
    if @runout_result
      {success: true, result: @runout_result}
    else
      {success: false, error: @runout_error}
    end
  end

  def build_wall_height_json_response
    if @wall_height_result
      {success: true, result: @wall_height_result}
    else
      {success: false, error: @wall_height_error}
    end
  end
end
