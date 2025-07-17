module InspectionTurboStreams
  extend ActiveSupport::Concern

  private

  def success_turbo_streams
    [
      mark_complete_section_stream,
      save_message_stream(success: true),
      assessment_save_message_stream(success: true)
    ]
  end

  def error_turbo_streams
    [
      mark_complete_section_stream,
      save_message_stream(success: false),
      assessment_save_message_stream(success: false)
    ]
  end

  def mark_complete_section_stream
    turbo_stream.replace(
      "mark_complete_section_#{@inspection.id}",
      partial: "inspections/mark_complete_section",
      locals: { inspection: @inspection }
    )
  end

  def save_message_stream(success:)
    turbo_stream.replace(
      "inspection_save_message",
      partial: "shared/save_message",
      locals: save_message_locals(
        success: success,
        dom_id: "inspection_save_message"
      )
    )
  end

  def assessment_save_message_stream(success:)
    turbo_stream.replace(
      "form_save_message",
      partial: "shared/save_message",
      locals: save_message_locals(success: success, dom_id: "form_save_message")
    )
  end

  def save_message_locals(success:, dom_id:)
    if success
      {
        dom_id: dom_id,
        success: true,
        message: t("inspections.messages.updated")
      }
    else
      {
        dom_id: dom_id,
        errors: @inspection.errors.full_messages,
        message: t("shared.messages.save_failed")
      }
    end
  end
end
