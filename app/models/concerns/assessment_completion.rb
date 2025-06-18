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
    (attributes.keys - SYSTEM_FIELDS).
      select {|f| !f.end_with?("_comment")}.
      select {|f| send(f) == nil}.
      map {|f| f.to_sym}
  end
end
