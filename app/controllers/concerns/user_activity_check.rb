module UserActivityCheck
  extend ActiveSupport::Concern

  private

  def require_user_active
    unless current_user.is_active?
      flash[:alert] = current_user.inactive_user_message
      handle_inactive_user_redirect
    end
  end

  # Override this method in controllers to provide custom redirect logic
  def handle_inactive_user_redirect
    raise NotImplementedError, "Controllers using UserActivityCheck must implement handle_inactive_user_redirect"
  end
end