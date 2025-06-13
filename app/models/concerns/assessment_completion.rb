module AssessmentCompletion
  extend ActiveSupport::Concern

  def complete?
    incomplete_fields.empty?
  end

  def incomplete_fields
    fields = []
    
    # Get all attribute names except system fields
    field_names = attributes.keys - %w[id inspection_id created_at updated_at]
    
    field_names.each do |field_name|
      # Skip comment fields - they're optional
      next if field_name.end_with?('_comment')
      
      # Skip if field has a value
      value = self.send(field_name)
      next if value.present? || value == false || value == 0
      
      # Add to incomplete fields
      fields << field_info(field_name.to_sym)
    end
    
    fields
  end

  private

  def field_info(field_name)
    {
      field: field_name,
      label: field_label(field_name),
      type: field_type(field_name)
    }
  end

  def field_label(field_name)
    # Get the assessment type from class name
    assessment_type = self.class.name.demodulize.underscore.sub(/_assessment$/, '')
    
    # Try to find the translation in the forms namespace
    key = "forms.#{assessment_type}.fields.#{field_name}"
    translation = I18n.t(key, default: nil)
    
    # Fall back to humanized field name if translation not found
    translation || field_name.to_s.humanize
  end

  def field_type(field_name)
    if field_name.to_s.end_with?('_pass')
      :pass_fail
    elsif field_name.to_s.start_with?('num_')
      :number
    else
      :text
    end
  end
end