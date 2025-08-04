# frozen_string_literal: true

class UsersController < ChobbleApp::UsersController
  private

  def load_app_specific_data
    @inspection_counts = Inspection
      .where(user_id: @users.pluck(:id))
      .group(:user_id)
      .count
  end

  def handle_app_specific_params
    # Convert empty string to nil for inspection_company_id
    if params[:user][:inspection_company_id] == ""
      params[:user][:inspection_company_id] = nil
    end
  end

  def user_params
    if current_user&.admin?
      admin_permitted_params = %i[
        active_until email inspection_company_id name password
        password_confirmation rpii_inspector_number
      ]
      params.require(:user).permit(admin_permitted_params)
    else
      super
    end
  end
end