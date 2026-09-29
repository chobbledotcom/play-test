# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

# Works out which fields of a new inspection, or one of its assessments, can
# offer the previous inspection's values as prefill, and builds the translated
# labels shown in the edit-page prefill notice.
class InspectionPrefillService
  extend T::Sig

  # Lifecycle and system fields never make sense as prefill hints, even when
  # the previous inspection carries a value
  PREFILL_EXCLUDED_FIELDS = %i[
    complete_date
    created_at
    id
    inspection_date
    inspection_id
    inspector_company_id
    is_seed
    passed
    pdf_last_accessed_at
    unit_id
    updated_at
    user_id
  ].freeze

  # The results tab edits inspection attributes directly rather than going
  # through an assessment record
  RESULT_TAB_FIELDS = %i[
    passed
    risk_assessment
    photo_1
    photo_2
    photo_3
  ].freeze

  # Tab name to the matching assessment getter on Inspection, derived from
  # ALL_ASSESSMENT_TYPES so the mapping cannot drift from the model
  ASSESSMENT_TAB_MAPPING = Inspection::ALL_ASSESSMENT_TYPES.keys
    .index_by { |assessment_name| assessment_name.to_s.delete_suffix("_assessment") }
    .freeze

  sig do
    params(
      inspection: Inspection,
      previous_inspection: T.nilable(Inspection),
      tab: T.nilable(String)
    ).void
  end
  def initialize(inspection, previous_inspection, tab)
    @inspection = inspection
    @previous_inspection = previous_inspection
    @tab = tab
  end

  sig { returns(T::Array[String]) }
  def field_labels
    return [] if @previous_inspection.nil?
    return [] if @previous_inspection.id == @inspection.id

    current_record, previous_record, fields = prefill_targets
    fields.filter_map do |field|
      next if PREFILL_EXCLUDED_FIELDS.include?(field)
      next if previous_record&.send(field).nil?
      next unless current_record.send(field).nil?

      field_label(field)
    end
  end

  private

  sig { returns([T.untyped, T.untyped, T::Array[Symbol]]) }
  def prefill_targets
    case @tab
    when "inspection", "", nil
      [@inspection, @previous_inspection, Inspection.column_name_syms]
    when "results"
      [@inspection, @previous_inspection, RESULT_TAB_FIELDS]
    else
      assessment_method = ASSESSMENT_TAB_MAPPING.fetch(@tab)
      assessment_class = Inspection::ALL_ASSESSMENT_TYPES.fetch(assessment_method)
      [
        @inspection.public_send(assessment_method),
        T.must(@previous_inspection).public_send(assessment_method),
        assessment_class.column_name_syms
      ]
    end
  end

  sig { params(field: Symbol).returns(String) }
  def field_label(field)
    is_comment = ChobbleForms::FieldUtils.is_comment_field?(field)
    is_pass = ChobbleForms::FieldUtils.is_pass_field?(field)
    field_base = ChobbleForms::FieldUtils.strip_field_suffix(field)
    tab_name = @tab.presence || :inspection
    i18n_base = "forms.#{tab_name}.fields"

    label = I18n.t("#{i18n_base}.#{field_base}", default: nil)
    label ||= I18n.t("#{i18n_base}.#{field}")

    if is_comment
      label += " (#{I18n.t("shared.comment")})"
    elsif is_pass
      label += " (#{I18n.t("shared.pass")}/#{I18n.t("shared.fail")})"
    end

    label
  end
end
