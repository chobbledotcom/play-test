# typed: true
# frozen_string_literal: true

class AssessmentGuidance
  extend T::Sig

  RULES = {
    "ball_pool" => {
      ball_pool_depth: [:<=, 450, :pool_depth],
      ball_pool_entry: [:<=, 630, :pool_entry],
      max_height_markings: [:<=, 1, :toddler_height],
      minimum_age: [:>=, 1, :toddler_age],
      maximum_age: [:<=, 3, :toddler_age]
    },
    "bungee" => {
      marking_max_mass: [:<=, 120, :mass],
      marking_min_height: [:>=, 1.2, :bungee_height],
      pull_strength: [:>=, 2400, :harness_pull],
      harness_width: [:>=, 200, :harness_width],
      rear_wall_thickness: [:>=, 0.6, :rear_wall],
      rear_wall_height: [:>=, 1.8, :rear_wall],
      side_wall_length: [:>=, 1.5, :starting_wall],
      side_wall_height: [:>=, 1.7, :starting_wall],
      running_wall_width: [:>=, 0.45, :running_wall],
      running_wall_height: [:>=, 0.9, :running_wall]
    },
    "catch_bed" => {
      max_user_mass_marking: [:<=, 120, :mass],
      bed_height: [:>=, 400, :catch_bed_height],
      platform_fall_distance: [:==, 1.8, :catch_platform],
      blower_tube_length: [:>=, 2.5, :catch_blower]
    },
    "inflatable_game" => {
      minimum_age: [nil, nil, :game_age],
      maximum_age: [nil, nil, :game_age],
      max_user_mass: [:<=, 120, :game_mass],
      containing_wall_height: [:>=, 0.9, :game_wall]
    },
    "play_zone" => {
      height_marking: [:<=, 1, :toddler_height],
      minimum_age: [:>=, 1, :toddler_age],
      maximum_age: [:<=, 3, :toddler_age],
      ball_pool_depth: [:<=, 450, :pool_depth],
      ball_pool_entry_height: [:<=, 630, :pool_entry],
      slide_gradient: [:<=, 64, :access_gradient],
      slide_platform_height: [:<=, 1.5, :zone_platform]
    }
  }.freeze

  GROUP_OUTCOMES = {
    rear_wall_thickness: :rear_wall_pass,
    rear_wall_height: :rear_wall_pass,
    side_wall_length: :side_wall_pass,
    side_wall_height: :side_wall_pass,
    running_wall_width: :running_wall_pass,
    running_wall_height: :running_wall_pass
  }.freeze

  sig { params(assessment: ApplicationRecord).void }
  def initialize(assessment)
    @assessment = assessment
    @type = assessment.class.model_name.element.delete_suffix("_assessment")
  end

  sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def comparisons
    return [] unless @assessment.inspection.current_checklist?
    fields = @assessment.form_schema.fields.map(&:name)
    return capacity_comparisons(fields) if @type == "user_height"
    RULES.fetch(@type, {}).filter_map do |name, rule|
      next unless fields.include?(name)
      next if not_applicable?(name)
      value = @assessment.public_send(name)
      next if value.nil?
      comparison(name, value, rule)
    end
  end

  private

  sig do
    params(fields: T::Array[Symbol])
      .returns(T::Array[T::Hash[Symbol, T.untyped]])
  end
  def capacity_comparisons(fields)
    length = @assessment.play_area_length
    width = @assessment.play_area_width
    adjustment = @assessment.negative_adjustment
    height = capacity_height_limit
    return [] if [length, width, adjustment, height].any?(&:nil?)
    return [] unless length.positive? && width.positive?
    return [] if adjustment > length * width
    capacities = EN14960.calculate_user_capacity(
      length.to_f, width.to_f, height.to_f, adjustment.to_f
    ).value
    capacities.filter_map do |key, maximum|
      name = key.to_s.sub("users_", "users_at_").to_sym
      next unless fields.include?(name)
      value = @assessment.public_send(name)
      next if value.nil?
      comparison(name, value, [:<=, maximum, :user_capacity])
    end
  end

  sig { returns(T.nilable(BigDecimal)) }
  def capacity_height_limit
    inspection = @assessment.inspection
    return @assessment.maximum_user_height unless
      inspection.inspection_type == "play_zone"
    zone = inspection.play_zone_assessment
    return if zone.height_marking_pass == "na"
    zone.height_marking
  end

  sig { params(name: Symbol).returns(T::Boolean) }
  def not_applicable?(name)
    outcome = if %i[minimum_age maximum_age].include?(name)
      (@type == "play_zone") ? :age_marking_pass : :age_range_marking_pass
    else
      GROUP_OUTCOMES.fetch(name, :"#{name}_pass")
    end
    @assessment.has_attribute?(outcome) &&
      @assessment.public_send(outcome) == "na"
  end

  sig do
    params(name: Symbol, value: T.untyped, rule: T.untyped)
      .returns(T::Hash[Symbol, T.untyped])
  end
  def comparison(name, value, rule)
    operator, threshold, context = rule
    within = operator && value.public_send(operator, BigDecimal(threshold.to_s))
    conditional_wall = context == :game_wall && value <= BigDecimal("0.63")
    status = if operator.nil?
      :recorded
    elsif conditional_wall
      :not_triggered
    else
      within ? :within : :outside
    end
    {
      field: name,
      value: value,
      status: status,
      context: context,
      reference: threshold,
      form: @type
    }
  end
end
