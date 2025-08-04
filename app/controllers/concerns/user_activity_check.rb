# typed: true
# frozen_string_literal: true

module UserActivityCheck
  extend ActiveSupport::Concern
  extend T::Sig

  private

  sig { void }
  def require_user_active
    return if current_user.is_active?

    flash[:alert] = current_user.inactive_user_message
    handle_inactive_user_redirect
  end

  # Override this method in controllers to provide custom redirect logic
  sig { void }
  def handle_inactive_user_redirect
    raise NotImplementedError
  end
end
