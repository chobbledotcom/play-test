module ChobbleApp
  module ApplicationHelper
  include ActionView::Helpers::NumberHelper

  def render_time(datetime) = datetime&.strftime("%b %d, %Y")

  def date_for_form(datetime) = datetime&.to_date

  def scrollable_table(html_options = {}, &block)
    content_tag(:div, class: "table-container") do
      content_tag(:table, html_options, &block)
    end
  end

  def effective_theme
    ENV["THEME"] || current_user&.theme || "light"
  end

  def theme_selector_disabled? = ENV["THEME"].present?

  def logo_path
    ENV["LOGO_PATH"] || "logo.svg"
  end

  def logo_alt_text
    ENV["LOGO_ALT"] || "play-test logo"
  end

  def left_logo_path
    ENV["LEFT_LOGO_PATH"]
  end

  def left_logo_alt
    ENV["LEFT_LOGO_ALT"] || "Logo"
  end

  def right_logo_path
    ENV["RIGHT_LOGO_PATH"]
  end

  def right_logo_alt
    ENV["RIGHT_LOGO_ALT"] || "Logo"
  end

  def page_snippet(slug)
    snippet = Page.snippets.find_by(slug: slug)
    return "" unless snippet
    raw snippet.content
  end

  def nav_link_to(name, path, options = {})
    css_class = if current_page?(path) || controller_matches?(path)
      "active"
    else
      ""
    end
    link_to name, path, options.merge(class: css_class)
  end

  def format_numeric_value(value)
    if value.is_a?(String) &&
        value.match?(/\A-?\d*\.?\d+\z/) &&
        (float_value = Float(value, exception: false))
      value = float_value
    end

    return value unless value.is_a?(Numeric)

    number_with_precision(
      value,
      precision: 4,
      strip_insignificant_zeros: true
    )
  end

  private

  def controller_matches?(path)
    route = Rails.application.routes.recognize_path(path)
    path_controller = route[:controller]
    controller_name == path_controller
  rescue ActionController::RoutingError
    false
  end
  end
end
