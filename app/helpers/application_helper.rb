# typed: strict
# frozen_string_literal: true

module ApplicationHelper
  extend T::Sig
  include ActionView::Helpers::NumberHelper

  sig { params(datetime: T.nilable(T.any(Time, DateTime, ActiveSupport::TimeWithZone))).returns(T.nilable(String)) }
  def render_time(datetime) = datetime&.strftime("%b %d, %Y")

  sig { params(datetime: T.nilable(T.any(Time, DateTime, ActiveSupport::TimeWithZone))).returns(T.nilable(Date)) }
  def date_for_form(datetime) = datetime&.to_date

  sig { params(html_options: T::Hash[T.untyped, T.untyped], block: T.proc.void).returns(String) }
  def scrollable_table(html_options = {}, &block)
    content_tag(:div, class: "table-container") do
      content_tag(:table, html_options, &block)
    end
  end

  sig { returns(String) }
  def effective_theme
    ENV["THEME"] || current_user&.theme || "light"
  end

  sig { returns(T::Boolean) }
  def theme_selector_disabled? = ENV["THEME"].present?

  sig { returns(String) }
  def logo_path
    ENV["LOGO_PATH"] || "logo.svg"
  end

  sig { returns(String) }
  def logo_alt_text
    ENV["LOGO_ALT"] || "play-test logo"
  end

  sig { returns(T.nilable(String)) }
  def left_logo_path
    ENV["LEFT_LOGO_PATH"]
  end

  sig { returns(String) }
  def left_logo_alt
    ENV["LEFT_LOGO_ALT"] || "Logo"
  end

  sig { returns(T.nilable(String)) }
  def right_logo_path
    ENV["RIGHT_LOGO_PATH"]
  end

  sig { returns(String) }
  def right_logo_alt
    ENV["RIGHT_LOGO_ALT"] || "Logo"
  end

  sig { params(slug: String).returns(T.any(String, ActiveSupport::SafeBuffer)) }
  def page_snippet(slug)
    snippet = Page.snippets.find_by(slug: slug)
    return "" unless snippet
    raw snippet.content
  end

  sig { params(name: String, path: String, options: T::Hash[T.untyped, T.untyped]).returns(String) }
  def nav_link_to(name, path, options = {})
    css_class = if current_page?(path) || controller_matches?(path)
      "active"
    else
      ""
    end
    link_to name, path, options.merge(class: css_class)
  end

  sig { params(value: T.untyped).returns(T.untyped) }
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

  sig { params(path: String).returns(T::Boolean) }
  def controller_matches?(path)
    route = Rails.application.routes.recognize_path(path)
    path_controller = route[:controller]
    controller_name == path_controller
  rescue ActionController::RoutingError
    false
  end
end
