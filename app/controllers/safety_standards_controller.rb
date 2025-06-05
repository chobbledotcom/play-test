# RPII Utility - Reference and calculation tools controller
class SafetyStandardsController < ApplicationController
  before_action :authenticate_user!

  # GET /safety_standards
  # Reference guide for inspection criteria
  def index
    @height_categories = SafetyStandard.height_categories
    @slide_calculations = SafetyStandard.slide_calculations
    @anchor_formulas = SafetyStandard.anchor_formulas
  end

  # GET /safety_standards/height_calculator
  # Interactive height calculation tool
  def height_calculator
    if params[:user_height].present?
      @user_height = params[:user_height].to_f
      @required_wall_height = SafetyStandard.calculate_required_wall_height(@user_height)
      @user_capacity = SafetyStandard.calculate_user_capacity(params[:play_area_length], 
                                                               params[:play_area_width])
    end
  end

  # GET /safety_standards/anchor_calculator
  # Anchor point calculation tool
  def anchor_calculator
    if params[:area].present?
      @area = params[:area].to_f
      @required_anchors = SafetyStandard.calculate_required_anchors(@area)
    end
  end

  # GET /safety_standards/slide_runout_calculator
  # Slide runout calculation tool
  def slide_runout_calculator
    if params[:platform_height].present?
      @platform_height = params[:platform_height].to_f
      @required_runout = SafetyStandard.calculate_slide_runout(@platform_height)
    end
  end
end