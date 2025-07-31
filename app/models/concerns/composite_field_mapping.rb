module CompositeFieldMapping
  extend ActiveSupport::Concern

  def get_composite_fields(field, partial)
    fields = []
    partial_str = partial.to_s

    if partial_str.include?("pass_fail") && !field.to_s.end_with?("_pass")
      fields << "#{field}_pass"
    end

    if partial_str.include?("comment")
      base = field.to_s.end_with?("_pass") ? strip_field_suffix(field) : field
      fields << "#{base}_comment"
    end

    fields
  end

  def strip_field_suffix(field)
    field.to_s.gsub(/_pass$|_comment$/, "")
  end

  class_methods do
    def get_composite_fields(field, partial)
      new.get_composite_fields(field, partial)
    end

    def strip_field_suffix(field)
      new.strip_field_suffix(field)
    end
  end
end
