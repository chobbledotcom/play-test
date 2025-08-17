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
    field_to_partial = build_field_to_partial_mapping
    incomplete = incomplete_fields
    group_incomplete_fields(incomplete, field_to_partial)
  end

  private

  sig { returns(T::Hash[Symbol, Symbol]) }
  def build_field_to_partial_mapping
    form_config = get_form_config
    field_to_partial = {}

    form_config.each do |section|
      next unless section[:fields]
      map_section_fields(section, field_to_partial)
    end

    field_to_partial
  end

  sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
  def get_form_config
    self.class.form_fields
  rescue
    []
  end

  sig do
    params(
      section: T::Hash[Symbol, T.untyped],
      field_to_partial: T::Hash[Symbol, Symbol]
    ).void
  end
  def map_section_fields(section, field_to_partial)
    section[:fields].each do |field_config|
      field = field_config[:field]
      partial = field_config[:partial]
      field_to_partial[field.to_sym] = partial

      # Also map composite fields
      partial_sym = partial.to_sym
      composite_fields = ChobbleForms::FieldUtils
        .get_composite_fields(field.to_sym, partial_sym)
      composite_fields.each do |cf|
        field_to_partial[cf.to_sym] = partial
      end
    end
  end

  sig do
    params(
      incomplete: T::Array[Symbol],
      field_to_partial: T::Hash[Symbol, Symbol]
    ).returns(T::Hash[Symbol, T::Hash[Symbol, T.untyped]])
  end
  def group_incomplete_fields(incomplete, field_to_partial)
    grouped = {}
    processed = Set.new

    incomplete.each do |field|
      next if processed.include?(field)
      process_field_group(
        field, incomplete, field_to_partial, grouped, processed
      )
    end

    grouped
  end

  sig do
    params(
      field: Symbol,
      incomplete: T::Array[Symbol],
      field_to_partial: T::Hash[Symbol, Symbol],
      grouped: T::Hash[Symbol, T::Hash[Symbol, T.untyped]],
      processed: Set
    ).void
  end
  def process_field_group(
    field, incomplete, field_to_partial, grouped, processed
  )
    base_field = ChobbleForms::FieldUtils.strip_field_suffix(field)
    partial = field_to_partial[field] || field_to_partial[base_field]

    # Find all related incomplete fields for this base
    related = incomplete.select do |f|
      ChobbleForms::FieldUtils.strip_field_suffix(f) == base_field
    end

    key = (related.size > 1) ? base_field : field
    grouped[key] = {
      fields: related,
      partial: partial
    }
    processed.merge(related)
  end

  sig { params(field: Symbol).returns(T::Boolean) }
  def field_is_incomplete?(field)
    value = send(field)
    # Field is incomplete if nil
    value.nil?
  end

  sig { params(field: Symbol).returns(T::Boolean) }
  def field_allows_nil_when_na?(field)
    # Pass fields are always required, even if set to "na"
    return false if field.end_with?("_pass")

    # Only allow nil for value fields when corresponding _pass field is "na"
    pass_field = "#{field}_pass"
    respond_to?(pass_field) && send(pass_field) == "na"
  end
end
