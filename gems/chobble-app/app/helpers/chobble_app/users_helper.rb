module ChobbleApp
  module UsersHelper
    def admin_status(user)
      user.admin? ? "Yes" : "No"
    end

    # App-specific helpers can be added in main app

    def format_job_time(time)
      return "Never" unless time
      "#{time_ago_in_words(time)} ago"
    end
  end
end
