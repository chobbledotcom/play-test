class HomeController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token, only: [:safety_standards]

  def index
  end

  def about
  end

  def safety_standards
    # Always provide calculation metadata for the view
    @calculation_metadata = SafetyStandard.calculation_metadata

    if request.post? && params[:calculation].present?
      calculate_safety_standard
      respond_to do |format|
        format.turbo_stream
        format.json { render json: build_json_response }
        format.html do
          # Preserve calculation params for the redirect so form values are maintained
          redirect_to safety_standards_path(calculation: params[:calculation].to_unsafe_h)
        end
      end
    else
      # Handle GET requests with calculation parameters (from redirect)
      if params[:calculation].present?
        calculate_safety_standard
      end
      respond_to do |format|
        format.html
      end
    end
  end

  private

  def calculate_safety_standard
    case params[:calculation][:type]
    when "anchors"
      calculate_anchors
    when "user_capacity"
      calculate_user_capacity
    when "slide_runout"
      calculate_slide_runout
    when "wall_height"
      calculate_wall_height
    end
  end

  def calculate_anchors
    area = params[:calculation][:area].to_f
    if area > 0
      @anchor_result = {
        area: area,
        required_anchors: SafetyStandard.calculate_required_anchors(area),
        formula_breakdown: "((#{area}² × 114) ÷ 1600) × 1.5 = #{SafetyStandard.calculate_required_anchors(area)}"
      }
    else
      @anchor_error = t("safety_standards_reference.errors.invalid_area")
    end
  end

  def calculate_user_capacity
    length = params[:calculation][:length].to_f
    width = params[:calculation][:width].to_f
    negative_adjustment = params[:calculation][:negative_adjustment].to_f

    if length > 0 && width > 0
      @capacity_result = {
        length: length,
        width: width,
        area: length * width,
        negative_adjustment: negative_adjustment,
        usable_area: (length * width) - negative_adjustment,
        capacities: SafetyStandard.calculate_user_capacity(length, width, negative_adjustment)
      }
    else
      @capacity_error = t("safety_standards_reference.errors.invalid_dimensions")
    end
  end

  def calculate_slide_runout
    platform_height = params[:calculation][:platform_height].to_f

    if platform_height > 0
      required_runout = SafetyStandard.calculate_required_runout(platform_height)
      @runout_result = {
        platform_height: platform_height,
        required_runout: required_runout,
        calculation: "50% of #{platform_height}m = #{platform_height * 0.5}m, minimum 0.3m = #{required_runout}m"
      }
    else
      @runout_error = t("safety_standards_reference.errors.invalid_platform_height")
    end
  end

  def calculate_wall_height
    user_height = params[:calculation][:user_height].to_f

    if user_height > 0
      @wall_height_result = {
        user_height: user_height,
        requirement: wall_height_requirement_text(user_height),
        requires_roof: SafetyStandard.requires_permanent_roof?(user_height)
      }
    else
      @wall_height_error = t("safety_standards_reference.errors.invalid_user_height")
    end
  end

  def wall_height_requirement_text(user_height)
    thresholds = SafetyStandard::SLIDE_HEIGHT_THRESHOLDS
    case user_height
    when 0..thresholds[:no_walls_required]
      "No containing walls required"
    when thresholds[:no_walls_required]..thresholds[:basic_walls]
      "Walls must be at least #{user_height}m (equal to user height)"
    when thresholds[:basic_walls]..thresholds[:enhanced_walls]
      "Walls must be at least #{(user_height * 1.25).round(2)}m (1.25× user height)"
    when thresholds[:enhanced_walls]..thresholds[:max_safe_height]
      "Walls must be at least #{(user_height * 1.25).round(2)}m + permanent roof required"
    else
      "Exceeds safe height limits (>#{thresholds[:max_safe_height]}m)"
    end
  end

  def build_json_response
    case params[:calculation][:type]
    when "anchors"
      if @anchor_result
        {success: true, result: @anchor_result}
      else
        {success: false, error: @anchor_error}
      end
    when "user_capacity"
      if @capacity_result
        {success: true, result: @capacity_result}
      else
        {success: false, error: @capacity_error}
      end
    when "slide_runout"
      if @runout_result
        {success: true, result: @runout_result}
      else
        {success: false, error: @runout_error}
      end
    when "wall_height"
      if @wall_height_result
        {success: true, result: @wall_height_result}
      else
        {success: false, error: @wall_height_error}
      end
    else
      {success: false, error: "Invalid calculation type"}
    end
  end
end
