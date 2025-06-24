module UnitTurboStreams
  extend ActiveSupport::Concern

  private

  def render_unit_update_success_stream
    render turbo_stream: build_unit_turbo_streams(
      success: true,
      message: t("units.messages.updated")
    )
  end

  def render_unit_update_error_stream
    render turbo_stream: build_unit_turbo_streams(
      success: false,
      message: t("shared.messages.save_failed"),
      errors: @unit.errors.full_messages
    )
  end

  def build_unit_turbo_streams(success:, message:, errors: nil)
    [
      build_save_message_stream(success: success, message: message, errors: errors)
      # Don't replace the file field - it stays as is after save
    ]
  end

  def build_save_message_stream(success:, message:, errors: nil)
    turbo_stream.replace("form_save_message",
      partial: "shared/save_message",
      locals: {
        message: message,
        errors: errors
      })
  end
end
