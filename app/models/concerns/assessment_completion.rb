# typed: true
# frozen_string_literal: true

module AssessmentCompletion
  extend ActiveSupport::Concern
  extend T::Sig

  SYSTEM_FIELDS = %i[
    id
    inspection_id
    created_at
    updated_at
  ].freeze

  sig { returns(T::Boolean) }
  def complete?
    incomplete_fields.empty?
  end

  sig { returns(T::Array[Symbol]) }
  def incomplete_fields
    (self.class.column_name_syms - SYSTEM_FIELDS)
      .reject { |f| f.end_with?("_comment") }
      .select { |f| field_is_incomplete?(f) }
      .reject { |f| field_allows_nil_when_na?(f) }
  end

  sig { returns(T::Hash[Symbol, T::Hash[Symbol, T.untyped]]) }
  def incomplete_fields_grouped
    incomplete = incomplete_fields
    grouped = {}
    processed = Set.new

    incomplete.each do |field|
      next if processed.include?(field)
      add_incomplete_group(field, incomplete, grouped, processed)
    end

    grouped
  end

  private

  sig do
    params(
      field: Symbol,
      incomplete: T::Array[Symbol],
      grouped: T::Hash[Symbol, T::Hash[Symbol, T.untyped]],
      processed: Set
    ).void
  end
  def add_incomplete_group(field, incomplete, grouped, processed)
    base = ChobbleForms::FieldUtils.strip_field_suffix(field)
    related = incomplete.select do |f|
      ChobbleForms::FieldUtils.strip_field_suffix(f) == base
    end

    key = (related.size > 1) ? base : field
    grouped[key] = {
      fields: related,
      partial: assessment_schema_partial_for(field)
    }
    processed.merge(related)
  end

  sig { params(field: Symbol).returns(T.nilable(Symbol)) }
  def assessment_schema_partial_for(field)
    self.class.assessment_schema.partial_for(field)
  rescue
    nil
  end

  sig { params(field: Symbol).returns(T::Boolean) }
  def field_is_incomplete?(field)
    send(field).nil?
  end

  sig { params(field: Symbol).returns(T::Boolean) }
  def field_allows_nil_when_na?(field)
    return false if field.end_with?("_pass")

    pass_field = "#{field}_pass"
    respond_to?(pass_field) && send(pass_field) == "na"
  end
end
