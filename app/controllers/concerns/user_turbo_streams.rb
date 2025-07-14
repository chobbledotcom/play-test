module UserTurboStreams
  extend ActiveSupport::Concern

  private

  def render_user_update_success_stream
    render turbo_stream: build_user_turbo_streams(
      success: true,
      message: t("users.messages.settings_updated")
    )
  end

  def render_user_update_error_stream
    render turbo_stream: build_user_turbo_streams(
      success: false,
      message: t("shared.messages.save_failed"),
      errors: @user.errors.full_messages
    )
  end

  def build_user_turbo_streams(success:, message:, errors: nil)
    [
      build_save_message_stream(
        success: success,
        message: message,
        errors: errors
      )
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
