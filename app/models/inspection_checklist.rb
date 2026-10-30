# typed: true
# frozen_string_literal: true

class InspectionChecklist
  extend T::Sig

  CURRENT_REVISION = 2
  DIMENSION_FIELDS = %i[height length width].freeze
  COMPONENT_FIELDS = %i[
    has_air_jugglers
    has_ancillary_equipment
    has_ball_pool
    has_blower
    has_containing_walls
    has_fencing
    has_inflatable_bed
    has_slide
    indoor_only
    is_totally_enclosed
  ].freeze
  COMPONENTS_BY_TYPE = {
    bouncy_castle: %i[has_slide indoor_only is_totally_enclosed],
    bouncing_pillow: %i[has_blower has_fencing],
    bungee_run: %i[indoor_only],
    catch_bed: %i[indoor_only],
    inflatable_ball_pool: %i[has_air_jugglers indoor_only],
    inflatable_game: %i[
      has_ancillary_equipment has_containing_walls has_inflatable_bed
      has_slide indoor_only is_totally_enclosed
    ],
    pat_testable: [],
    play_zone: %i[
      has_air_jugglers has_ball_pool has_slide indoor_only
      is_totally_enclosed
    ]
  }.transform_values(&:freeze).freeze
  LEGACY_ASSESSMENTS = {
    bouncy_castle: %i[
      user_height_assessment slide_assessment structure_assessment
      anchorage_assessment materials_assessment enclosed_assessment fan_assessment
    ],
    bouncing_pillow: %i[fan_assessment],
    bungee_run: %i[
      structure_assessment materials_assessment fan_assessment
      anchorage_assessment bungee_assessment
    ],
    catch_bed: %i[
      structure_assessment materials_assessment fan_assessment
      anchorage_assessment catch_bed_assessment
    ],
    inflatable_ball_pool: %i[
      structure_assessment materials_assessment fan_assessment ball_pool_assessment
    ],
    inflatable_game: %i[
      structure_assessment materials_assessment fan_assessment
      inflatable_game_assessment
    ],
    pat_testable: %i[pat_assessment],
    play_zone: %i[
      structure_assessment materials_assessment fan_assessment
      user_height_assessment slide_assessment play_zone_assessment
    ]
  }.transform_values(&:freeze).freeze
  PLATFORM_FIELDS = %i[
    critical_fall_off_height platform_height step_ramp_size
  ].freeze
  TROUGH_FIELDS = %i[
    trough trough_adjacent_panel_width trough_depth
  ].freeze
  FENCING_FIELDS = %i[
    fencing_distance fencing_entrapment fencing_gateways fencing_height
    fencing_strength fencing_visibility
  ].freeze
  PLAY_ZONE_POOL_FIELDS = %i[
    ball_pool_depth ball_pool_entry_height ball_pool_gaps balls fitted_sheet
  ].freeze

  sig { params(type: T.any(String, Symbol)).returns(T::Array[Symbol]) }
  def self.component_fields(type)
    COMPONENTS_BY_TYPE.fetch(type.to_sym)
  end

  sig { params(type: T.any(String, Symbol)).returns(T::Boolean) }
  def self.constant_air?(type)
    !%i[bouncing_pillow pat_testable].include?(type.to_sym)
  end

  sig do
    params(type: T.any(String, Symbol)).returns(T::Hash[Symbol, T::Boolean])
  end
  def self.configuration_defaults(type)
    COMPONENT_FIELDS.to_h do |field|
      [field, field == :has_blower && constant_air?(type)]
    end
  end

  sig { params(record: T.untyped, type: T.any(String, Symbol)).void }
  def self.initialise_configuration(record, type)
    configuration_defaults(type).each do |field, default|
      record[field] = default if record[field].nil?
    end
  end

  sig { params(record: T.untyped, type: T.any(String, Symbol)).void }
  def self.normalise_type_change(record, type)
    allowed = component_fields(type)
    (COMPONENT_FIELDS - allowed - %i[has_blower]).each do |field|
      record[field] = false
    end
    record.has_blower = constant_air?(type) unless type.to_sym == :bouncing_pillow
  end

  sig { params(record: T.untyped, type: T.any(String, Symbol)).void }
  def self.validate_configuration(record, type)
    allowed = component_fields(type)
    allowed += %i[has_blower] if constant_air?(type)
    (COMPONENT_FIELDS - allowed).each do |field|
      record.errors.add(field, :not_applicable_to_unit_type) if record[field]
    end
    if constant_air?(type) && !record.has_blower?
      record.errors.add(:has_blower, :required_for_constant_air)
    end
  end

  sig { params(inspection: T.untyped).void }
  def initialize(inspection)
    @inspection = inspection
  end

  sig { returns(T::Array[Symbol]) }
  def assessment_names
    names = if @inspection.current_checklist?
      @inspection.assessment_types.keys
    else
      LEGACY_ASSESSMENTS.fetch(type)
    end
    names.select { |name| assessment_included?(name) }
  end

  sig { returns(T::Array[Symbol]) }
  def required_inspection_fields
    fields = %i[inspection_date]
    fields += DIMENSION_FIELDS unless type == :pat_testable
    return legacy_inspection_fields(fields) unless @inspection.current_checklist?

    fields += self.class.component_fields(type)
    fields << :inspection_location if type == :bouncing_pillow
    fields
  end

  sig do
    params(key: Symbol, schema: AssessmentSchema).returns(AssessmentSchema)
  end
  def filter_schema(key, schema)
    revision = @inspection.current_checklist? ? CURRENT_REVISION : 1
    schema = schema.for_revision(revision)
    return schema unless @inspection.current_checklist?

    excluded = excluded_fields(key, schema)
    schema.exclude(*excluded)
  end

  private

  sig { returns(Symbol) }
  def type = @inspection.inspection_type.to_sym

  sig { params(name: Symbol).returns(T::Boolean) }
  def assessment_included?(name)
    return legacy_assessment_included?(name) unless @inspection.current_checklist?

    case name
    when :slide_assessment then @inspection.has_slide?
    when :enclosed_assessment then @inspection.is_totally_enclosed?
    when :anchorage_assessment then !@inspection.indoor_only?
    when :fan_assessment
      type != :bouncing_pillow || @inspection.has_blower?
    else true
    end
  end

  sig { params(name: Symbol).returns(T::Boolean) }
  def legacy_assessment_included?(name)
    if type == :bouncy_castle
      case name
      when :slide_assessment then return @inspection.has_slide?
      when :enclosed_assessment then return @inspection.is_totally_enclosed?
      when :anchorage_assessment then return !@inspection.indoor_only?
      end
    end
    return @inspection.has_slide? if type == :play_zone &&
      name == :slide_assessment

    true
  end

  sig { params(fields: T::Array[Symbol]).returns(T::Array[Symbol]) }
  def legacy_inspection_fields(fields)
    return fields + %i[has_slide indoor_only is_totally_enclosed] if
      type == :bouncy_castle
    return fields + %i[has_slide] if type == :play_zone

    fields
  end

  sig do
    params(key: Symbol, schema: AssessmentSchema).returns(T::Array[Symbol])
  end
  def excluded_fields(key, schema)
    case key
    when :inspection
      schema.fields.map(&:name) - required_inspection_fields
    when :structure_assessment then excluded_structure_fields
    when :play_zone_assessment then excluded_play_zone_fields
    when :inflatable_game_assessment then excluded_game_fields
    when :bouncing_pillow_assessment
      @inspection.has_fencing? ? [] : FENCING_FIELDS
    when :ball_pool_assessment
      @inspection.has_air_jugglers? ? [] : %i[air_jugglers_compliant]
    when :fan_assessment
      type == :bouncing_pillow ? %i[blower_flap blower_tube_length] : []
    when :user_height_assessment
      type == :play_zone ? %i[maximum_user_height] : []
    when :anchorage_assessment
      type == :bungee_run ? [] : %i[bungee_side_area]
    else []
    end
  end

  sig { returns(T::Array[Symbol]) }
  def excluded_structure_fields
    fields = []
    if %i[bungee_run catch_bed inflatable_ball_pool].include?(type)
      fields += PLATFORM_FIELDS + TROUGH_FIELDS
    end
    fields += %i[grounding straight_walls] if type == :catch_bed
    return fields unless type == :inflatable_game

    fields << :straight_walls unless @inspection.has_containing_walls?
    fields += PLATFORM_FIELDS unless @inspection.has_slide?
    unless @inspection.has_inflatable_bed?
      fields += TROUGH_FIELDS + %i[evacuation_time grounding]
    end
    fields
  end

  sig { returns(T::Array[Symbol]) }
  def excluded_play_zone_fields
    fields = []
    fields += PLAY_ZONE_POOL_FIELDS unless @inspection.has_ball_pool?
    fields << :air_juggler unless @inspection.has_air_jugglers?
    unless @inspection.has_slide?
      fields += %i[slide_gradient slide_platform_height]
    end
    fields
  end

  sig { returns(T::Array[Symbol]) }
  def excluded_game_fields
    fields = []
    fields << :max_user_mass unless @inspection.has_inflatable_bed?
    fields << :containing_wall_height unless @inspection.has_containing_walls?
    unless @inspection.has_ancillary_equipment?
      fields += %i[ancillary_equipment ancillary_equipment_compliant]
    end
    fields
  end
end
