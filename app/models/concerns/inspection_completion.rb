# typed: true
# frozen_string_literal: true

# Handles inspection completion checks, missing field
# detection, and assessment validation.
module InspectionCompletion
  extend ActiveSupport::Concern
  extend T::Sig

  included do
    extend T::Sig
  end

  sig { returns(T::Boolean) }
  def can_be_completed?
    base_met = unit.present? &&
      all_assessments_complete? &&
      !passed.nil? &&
      inspection_date.present?

    return false unless base_met

    required = self.class::INSPECTION_TAB_FIELDS.fetch(
      inspection_type.to_sym, self.class::DIMENSION_FIELDS
    ) - %i[inspection_date]

    required.all? { |f| !send(f).nil? }
  end

  sig { returns(T::Boolean) }
  def can_mark_complete? = can_be_completed?

  sig { returns(T::Array[String]) }
  def completion_errors
    errors = []
    if unit.blank?
      errors << I18n.t("inspections.errors.unit_required")
    end

    incomplete_fields.each do |tab_info|
      tab_name = tab_info[:name]
      field_names = tab_info[:fields]
        .map { |f| f[:label] }.join(", ")
      errors << "#{tab_name}: #{field_names}"
    end

    errors
  end

  sig { returns(T::Array[String]) }
  def get_missing_assessments
    missing = []
    if unit.blank?
      missing << I18n.t("inspections.errors.unit_required")
    end

    each_applicable_assessment do |assessment_key, _, assessment|
      next if assessment&.complete?

      assessment_type = assessment_key.to_s
        .sub("_assessment", "")
      missing << I18n.t("forms.#{assessment_type}.header")
    end

    missing
  end

  sig { params(user: User).void }
  def complete!(user)
    update!(complete_date: Time.current)
    log_audit_action(
      "completed", user,
      I18n.t("inspections.messages.marked_complete")
    )
  end

  sig { params(user: User).void }
  def un_complete!(user)
    update!(complete_date: nil)
    log_audit_action(
      "marked_incomplete", user,
      I18n.t("inspections.messages.marked_incomplete")
    )
  end

  sig { returns(T::Array[String]) }
  def validate_completeness
    assessment_validation_data.filter_map do |name, assessment, msg|
      assessment_key = :"#{name}_assessment"
      next unless assessment_applicable?(assessment_key)

      msg if assessment.present? && !assessment.complete?
    end
  end

  sig { returns(T::Array[Symbol]) }
  def inspection_tab_incomplete_fields
    fields = self.class::INSPECTION_TAB_FIELDS.fetch(
      inspection_type.to_sym, self.class::DIMENSION_FIELDS
    )

    fields.select { |f| send(f).nil? }
  end

  sig {
    returns(
      T::Array[
        T::Hash[
          Symbol,
          T.any(
            Symbol, String,
            T::Array[T::Hash[Symbol, T.any(Symbol, String)]]
          )
        ]
      ]
    )
  }
  def incomplete_fields
    output = []

    applicable_tabs.each do |tab|
      case tab
      when "inspection"
        add_inspection_tab_fields(output)
      when "results"
        add_results_tab_fields(output)
      else
        add_assessment_tab_fields(output, tab)
      end
    end

    output
  end

  private

  sig {
    returns(
      T::Array[
        T::Array[T.any(Symbol, ActiveRecord::Base, String)]
      ]
    )
  }
  def assessment_validation_data
    self.class::ALL_ASSESSMENT_TYPES.keys.map do |key|
      type = key.to_s.sub("_assessment", "").to_sym
      assessment = send(key)
      msg = I18n.t(
        "inspections.validation.#{type}_incomplete"
      )
      [type, assessment, msg]
    end
  end

  sig { params(output: T::Array[T.untyped]).void }
  def add_inspection_tab_fields(output)
    fields = inspection_tab_incomplete_fields.map do |f|
      {field: f, label: field_label(:inspection, f)}
    end

    return unless fields.any?

    output << {
      tab: :inspection,
      name: I18n.t("forms.inspection.header"),
      fields: fields
    }
  end

  sig { params(output: T::Array[T.untyped]).void }
  def add_results_tab_fields(output)
    return unless passed.nil?

    output << {
      tab: :results,
      name: I18n.t("forms.results.header"),
      fields: [
        {field: :passed, label: field_label(:results, :passed)}
      ]
    }
  end

  sig {
    params(
      output: T::Array[T.untyped],
      tab: String
    ).void
  }
  def add_assessment_tab_fields(output, tab)
    assessment_key = :"#{tab}_assessment"
    return unless respond_to?(assessment_key)

    assessment = send(assessment_key)
    return unless assessment

    fields = build_assessment_fields(assessment, tab)
    return unless fields.any?

    output << {
      tab: tab.to_sym,
      name: I18n.t("forms.#{tab}.header"),
      fields: fields
    }
  end

  sig {
    params(
      assessment: ApplicationRecord,
      tab: String
    ).returns(
      T::Array[T::Hash[Symbol, T.any(Symbol, String)]]
    )
  }
  def build_assessment_fields(assessment, tab)
    assessment.incomplete_fields_grouped
      .map do |base_field, info|
        label = incomplete_field_label(
          tab, base_field, info
        )
        {field: base_field, label: label}
      end
  end

  sig {
    params(
      tab: String,
      base_field: Symbol,
      info: T::Hash[Symbol, T.untyped]
    ).returns(String)
  }
  def incomplete_field_label(tab, base_field, info)
    has_value = info[:fields].include?(base_field)
    pass_key = :"#{base_field}_pass"
    has_pass = info[:fields].include?(pass_key)
    base_label = field_label(tab.to_sym, base_field)

    if has_value && has_pass
      I18n.t("inspections.fields.value_and_pass_fail",
        label: base_label)
    elsif has_pass
      I18n.t("inspections.fields.pass_fail_only",
        label: base_label)
    else
      base_label
    end
  end
end
