module InspectionTurboStreams
  extend ActiveSupport::Concern

  private

  def success_turbo_streams
    [
      progress_update_stream,
      completion_issues_stream,
      save_message_stream(success: true),
      assessment_save_message_stream(success: true)
    ]
  end

  def error_turbo_streams
    [
      progress_update_stream,
      completion_issues_stream,
      save_message_stream(success: false),
      assessment_save_message_stream(success: false)
    ]
  end

  def progress_update_stream
    turbo_stream.replace(
      "inspection_progress_#{@inspection.id}",
      html: progress_html
    )
  end

  def completion_issues_stream
    turbo_stream.replace(
      "completion_issues_#{@inspection.id}",
      partial: "inspections/completion_issues",
      locals: {inspection: @inspection}
    )
  end

  def save_message_stream(success:)
    turbo_stream.replace(
      "inspection_save_message",
      partial: "shared/save_message",
      locals: save_message_locals(success: success, dom_id: "inspection_save_message")
    )
  end

  def assessment_save_message_stream(success:)
    turbo_stream.replace(
      "form_save_message",
      partial: "shared/save_message",
      locals: save_message_locals(success: success, dom_id: "form_save_message")
    )
  end

  def progress_html
    "<span class='value'>#{helpers.assessment_completion_percentage(@inspection)}%</span>"
  end

  def save_message_locals(success:, dom_id:)
    if success
      {
        dom_id: dom_id,
        success: true,
        success_message: t("inspections.messages.updated")
      }
    else
      {
        dom_id: dom_id,
        errors: @inspection.errors.full_messages,
        error_message: t("shared.messages.save_failed")
      }
    end
  end
end
