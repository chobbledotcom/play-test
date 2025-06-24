module UserTurboStreams
  extend ActiveSupport::Concern

  private

  def render_user_update_success_stream
    render turbo_stream: [
      build_save_message_stream(success: true, message: t("users.messages.settings_updated")),
      turbo_stream.replace("user_logo_preview",
        partial: "shared/attached_image",
        locals: {attachment: @user.logo, size: :thumbnail})
    ]
  end

  def render_user_update_error_stream
    render turbo_stream: [
      build_save_message_stream(
        success: false,
        errors: @user.errors.full_messages,
        message: t("shared.messages.save_failed")
      ),
      turbo_stream.replace("user_logo_preview",
        partial: "shared/attached_image",
        locals: {attachment: @user.logo, size: :thumbnail})
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
