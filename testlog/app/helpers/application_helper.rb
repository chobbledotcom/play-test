module ApplicationHelper
  TIME_FORMATS = {
    "date" => "%b %d, %Y",
    "time" => "%b %d, %Y - %H:%M"
  }

  def render_time(datetime)
    return nil if datetime.nil?

    format = TIME_FORMATS[current_user&.time_display] || TIME_FORMATS["date"]
    datetime.strftime(format)
  end

  def date_for_form(datetime)
    return nil if datetime.nil?

    if current_user&.time_display == "date"
      datetime.to_date
    else
      datetime
    end
  end

  def scrollable_table(html_options = {}, &block)
    content_tag(:div, class: "table-container") do
      content_tag(:table, html_options, &block)
    end
  end
end
