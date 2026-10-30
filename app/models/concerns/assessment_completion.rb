# typed: true
# frozen_string_literal: true

module AssessmentCompletion
  extend ActiveSupport::Concern
  extend T::Sig

  # Outcome fields that stored pass/fail/na enums BEFORE this checklist
  # revision existed; everything else with a revision-1 *_pass was a plain
  # boolean and must export as one for legacy reports.
  ORIGINAL_ENUM_FIELDS = {
    "FanAssessment" => %i[pat_pass blower_flap_pass],
    "MaterialsAssessment" => %i[
      ropes_pass retention_netting_pass zips_pass windows_pass artwork_pass
    ],
    "SlideAssessment" => %i[clamber_netting_pass],
    "StructureAssessment" => %i[
      step_ramp_size_pass platform_height_pass critical_fall_off_height_pass
      trough_pass grounding_pass
    ]
  }.freeze

  included do
    AssessmentSchema.for(self).attribute_names
      .select { it.end_with?("_pass") }.each do |field|
      enum field, {fail: 0, pass: 1, na: 2}, prefix: true
    end
  end

  class_methods do
    extend T::Sig

    sig { returns(T::Array[Symbol]) }
    def legacy_boolean_outcome_fields
      original = ORIGINAL_ENUM_FIELDS.fetch(name.demodulize, [])
      AssessmentSchema.for(self).for_revision(1).attribute_names
        .select { it.end_with?("_pass") } - original
    end
  end

  sig { returns(T::Boolean) }
  def complete? = incomplete_fields.empty?

  sig { returns(T::Array[Symbol]) }
  def incomplete_fields
    schema = form_schema
    fields = schema.attribute_names & self.class.column_name_syms
    fields -= schema.completion_optional_fields
    fields.reject { it.end_with?("_comment") }.select do |field|
      value = public_send(field)
      (value.nil? || (value.is_a?(String) && value.blank?)) &&
        !measurement_not_applicable?(field)
    end
  end

  sig { returns(T::Hash[Symbol, T::Hash[Symbol, T.untyped]]) }
  def incomplete_fields_grouped
    incomplete_fields.group_by do |field|
      ChobbleForms::FieldUtils.strip_field_suffix(field).to_sym
    end.to_h do |base, fields|
      key = (fields.size > 1) ? base : fields.first
      [key, {fields: fields, partial: form_schema.partial_for(base)}]
    end
  end

  sig { params(field: Symbol).returns(T::Boolean) }
  def measurement_not_applicable?(field)
    return false if field.end_with?("_pass", "_comment")

    outcome = outcome_field_for(field)
    !outcome.nil? && public_send(outcome) == "na"
  end

  private

  # A measurement is exempted from completion when the outcome covering its
  # group is marked N/A. Most measurements own "#{field}_pass", but grouped
  # measurements share one outcome (the bungee walls share rear_wall_pass)
  # and the age markings share the marking outcome, so resolve the longest
  # matching outcome field.
  sig { params(field: Symbol).returns(T.nilable(Symbol)) }
  def outcome_field_for(field)
    if %i[minimum_age maximum_age].include?(field)
      return form_schema.attribute_names.find do |name|
        %i[age_range_marking_pass age_marking_pass].include?(name)
      end
    end

    form_schema.attribute_names.select do |name|
      next false unless name.end_with?("_pass")

      base = name.to_s.delete_suffix("_pass")
      field == base.to_sym || field.start_with?("#{base}_")
    end.max_by { it.to_s.length }
  end
end
