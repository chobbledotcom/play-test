module AssessmentCompletion
  extend ActiveSupport::Concern

  SYSTEM_FIELDS = %w[
    id
    inspection_id
    created_at
    updated_at
  ]

  def complete?
    incomplete_fields.empty?
  end

  def incomplete_fields
    (attributes.keys - SYSTEM_FIELDS)
      .select { |f| !f.end_with?("_comment") }
      .select { |f| field_is_incomplete?(f) }
      .reject { |f| field_allows_nil_when_na?(f) }
      .map { |f| f.to_sym }
  end

  def incomplete_fields_grouped
    # Get form configuration to understand field relationships
    form_config = begin
      self.class.form_fields
    rescue
      []
    end
    field_to_partial = {}

    # Build mapping of field names to their partials
    form_config.each do |section|
      next unless section[:fields]
      section[:fields].each do |field_config|
        field = field_config[:field]
        partial = field_config[:partial]
        field_to_partial[field.to_sym] = partial

        # Also map composite fields
        composite_fields = FieldUtils.get_composite_fields(field, partial)
        composite_fields.each do |cf|
          field_to_partial[cf.to_sym] = partial
        end
      end
    end

    # Get all incomplete fields (already filtered for NA fields)
    incomplete = incomplete_fields

    # Group related fields
    grouped = {}
    processed = Set.new

    incomplete.each do |field|
      next if processed.include?(field)

      base_field = FieldUtils.strip_field_suffix(field).to_sym
      partial = field_to_partial[field] || field_to_partial[base_field]

      # Find all related incomplete fields for this base
      related = incomplete.select { |f| FieldUtils.strip_field_suffix(f).to_sym == base_field }

      key = (related.size > 1) ? base_field : field
      grouped[key] = {
        fields: related,
        partial: partial
      }
      processed.merge(related)
    end

    grouped
  end

  private

  def field_is_incomplete?(field)
    value = send(field)
    # Field is incomplete if nil
    return true if value.nil?
    # Pass fields with "na" value are also incomplete (pass fields require actual pass/fail value)
    field.end_with?("_pass") && value == "na"
  end

  def field_allows_nil_when_na?(field)
    # Pass fields are always required, even if set to "na"
    return false if field.end_with?("_pass")

    # Only allow nil for value fields when their corresponding _pass field is "na"
    pass_field = "#{field}_pass"
    respond_to?(pass_field) && send(pass_field) == "na"
  end
end
