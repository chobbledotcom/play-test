module AssessmentLogging
  extend ActiveSupport::Concern

  included do
    after_update :log_assessment_update, if: :saved_changes?
  end

  private

  def log_assessment_update
    assessment_type = self.class.name.underscore.humanize
    inspection.log_audit_action(
      "assessment_updated",
      inspection.user,
      "#{assessment_type} updated"
    )
  end
end
