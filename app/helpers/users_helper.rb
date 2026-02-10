# typed: strict
# frozen_string_literal: true

module UsersHelper
  extend T::Sig

  sig { params(user: User).returns(String) }
  def admin_status(user)
    user.admin? ? "Yes" : "No"
  end

  sig { params(user: User).returns(String) }
  def inspection_count(user)
    count = user.inspections.count
    "#{count} #{(count == 1) ? "inspection" : "inspections"}"
  end

  sig { params(time: T.nilable(T.any(Time, DateTime, ActiveSupport::TimeWithZone))).returns(String) }
  def format_job_time(time)
    return "Never" unless time
    "#{time_ago_in_words(time)} ago"
  end

  sig { params(user: User).returns(String) }
  def user_activity_indicator(user)
    if user.is_active?
      days = (Date.current - user.created_at.to_date).to_i
      label = I18n.t("users.status.active", days:)
      tag.data(label, value: "active")
    else
      days = (Date.current - user.active_until).to_i
      label = I18n.t("users.status.inactive", days:)
      tag.data(label, value: "inactive")
    end
  end
end
