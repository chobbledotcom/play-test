# frozen_string_literal: true

module UsersHelper
  include ChobbleApp::UsersHelper

  def inspection_count(user)
    count = user.inspections.count
    "#{count} #{(count == 1) ? "inspection" : "inspections"}"
  end
end