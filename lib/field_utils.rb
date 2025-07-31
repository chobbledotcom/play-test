module FieldUtils
  def self.strip_field_suffix(field)
    field.to_s.gsub(/_pass$|_comment$/, "")
  end

  def self.get_composite_fields(field, partial)
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

  def self.is_pass_field?(field)
    field.to_s.end_with?("_pass")
  end

  def self.is_comment_field?(field)
    field.to_s.end_with?("_comment")
  end

  def self.is_composite_field?(field)
    is_pass_field?(field) || is_comment_field?(field)
  end

  def self.base_field_name(field)
    strip_field_suffix(field)
  end
end
