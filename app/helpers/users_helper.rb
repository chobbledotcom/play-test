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
end
