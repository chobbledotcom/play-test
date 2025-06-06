module UsersHelper
  def admin_status(user)
    user.admin? ? "Yes" : "No"
  end

  def inspection_count(user)
    count = user.inspections.count
    "#{count} #{(count == 1) ? "inspection" : "inspections"}"
  end

  def format_job_time(time)
    return "Never" unless time
    "#{time_ago_in_words(time)} ago"
  end
end
