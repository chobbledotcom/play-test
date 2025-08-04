# frozen_string_literal: true

class SessionsController < ChobbleApp::SessionsController
  private

  def after_login_path
    inspections_path
  end
end
