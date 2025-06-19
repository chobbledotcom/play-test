module UnitTurboStreams
  extend ActiveSupport::Concern

  private

  def render_unit_update_success_stream
    render turbo_stream: [
      build_save_message_stream(success: true, message: t("units.messages.updated")),
      turbo_stream.replace("unit_photo_preview",
        partial: "shared/unit_photo_preview",
        locals: {unit: @unit})
    ]
  end

  def render_unit_update_error_stream
    render turbo_stream: [
      build_save_message_stream(
        success: false,
        errors: @unit.errors.full_messages,
        message: t("shared.messages.save_failed")
      )
    ]
  end

  def build_save_message_stream(success:, message:, errors: nil)
    turbo_stream.replace("form_save_message",
      partial: "shared/save_message",
      locals: {
        dom_id: "form_save_message",
        success: success,
        success_message: success ? message : nil,
        errors: errors,
        error_message: success ? nil : message
      })
  end
end
