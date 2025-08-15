# typed: true
# frozen_string_literal: true

module InspectionTabs
  extend ActiveSupport::Concern
  extend T::Sig

  private

  sig { void }
  def set_current_tab
    # Normalize the tab parameter safely
    @current_tab = helpers.normalize_tab_param params[:tab]

    # Check if it's valid for this specific inspection
    valid_tabs = helpers.inspection_tabs @inspection

    return if valid_tabs.include? @current_tab

    # Invalid tab - raise error
    raise ActionController::RoutingError, "Invalid tab: #{params[:tab]}"
  end
end
