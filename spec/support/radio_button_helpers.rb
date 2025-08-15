# typed: strict
# frozen_string_literal: true

module RadioButtonHelpers
  extend T::Sig

  BOOLEANS_BY_FORM = T.let({
    inspection: %i[has_slide is_totally_enclosed passed],
    slide_assessment: %i[slide_permanent_roof]
  }.freeze, T::Hash[Symbol, T::Array[Symbol]])

  sig { params(field_label: String, value: T::Boolean).void }
  def choose_yes_no(field_label, value)
    choose_radio_in_container field_label, value,
      ["radio-comment"],
      yes: ["yes", "pass"],
      no: ["no", "fail"]
  end

  sig { params(field_label: String, value: T.any(T::Boolean, String)).void }
  def choose_pass_fail(field_label, value)
    # Convert boolean to enum string for pass/fail fields
    converted_value = case value
    when true then "pass"
    when false then "fail"
    else value
    end
    find_and_click_radio field_label, converted_value
  end

  sig { params(field_label: String).void }
  def check_radio(field_label)
    choose_yes_no field_label, true
  end

  sig { params(field_label: String).void }
  def uncheck_radio(field_label)
    choose_yes_no field_label, false
  end

  sig { params(field_label: String).returns Symbol }
  def field_label_to_field_name(field_label)
    find_field_by_label(field_label) { |field| field }
  end

  sig { params(field_label: String).returns String }
  def field_label_to_name(field_label)
    find_field_by_label(field_label) { |field, model| "#{model}[#{field}]" }
  end

  private

  # XPath selector builders
  sig { params(label: String).returns String }
  def label_xpath(label)
    "//label[normalize-space(.)='#{label}']"
  end

  sig { params(label: String).returns String }
  def div_with_label_xpath(label)
    "//div[.//label[normalize-space(.)='#{label}']]"
  end

  sig { returns String }
  def pass_fail_div_xpath
    "div[@class='pass-fail']"
  end

  sig { params(value: T.nilable(String)).returns String }
  def radio_input_xpath(value = nil)
    base = "input[@type='radio']"
    value ? "#{base}[@value='#{value}']" : base
  end

  # Text helpers for radio values
  sig { params(value: T::Boolean, style: Symbol).returns String }
  def radio_text_for_boolean(value, style = :yes_no)
    case style
    when :yes_no
      value ? "Yes" : "No"
    when :pass_fail
      value ? "Pass" : "Fail"
    else
      T.absurd style
    end
  end

  sig { params(value: T.any(T::Boolean, String)).returns String }
  def boolean_to_radio_value(value)
    case value
    when true then "pass"
    when false then "fail"
    else value.to_s
    end
  end

  sig { params(label: String, value: T::Boolean, containers: T::Array[String], selectors: T::Hash[Symbol, T::Array[String]]).void }
  def choose_radio_in_container(label, value, containers, selectors)
    # Try primary approach first
    return if try_find_radio_in_form_grid label, value

    # Try alternative selectors
    return if try_alternative_radio_selectors label, value

    raise Capybara::ElementNotFound, "Unable to find radio for '#{label}'"
  end

  sig { params(label: String, value: T::Boolean).returns T::Boolean }
  def try_find_radio_in_form_grid(label, value)
    container_xpath = build_form_grid_container_xpath label
    container = find :xpath, container_xpath

    within container do
      click_radio_in_pass_fail_div value
    end
    true
  rescue Capybara::ElementNotFound
    false
  end

  sig { params(label: String, value: T::Boolean).returns T::Boolean }
  def try_alternative_radio_selectors(label, value)
    build_alternative_radio_selectors(label, value).each do |selector|
      find(:xpath, selector).click
      return true
    rescue Capybara::ElementNotFound
      next
    end
    false
  end

  sig { params(label: String).returns String }
  def build_form_grid_container_xpath(label)
    "//div[@class='form-grid radio-comment'][.//label[@class='label']" \
    "[normalize-space(.)='#{label}']]"
  end

  sig { params(label: String, value: T::Boolean).returns T::Array[String] }
  def build_alternative_radio_selectors(label, value)
    yes_no_text = radio_text_for_boolean value, :yes_no
    pass_fail_text = radio_text_for_boolean value, :pass_fail

    [
      "#{label_xpath label}/following-sibling::#{pass_fail_div_xpath}" \
      "//label[contains(.,'#{yes_no_text}')]/#{radio_input_xpath}",

      "#{label_xpath label}/following-sibling::#{pass_fail_div_xpath}" \
      "//label[contains(.,'#{pass_fail_text}')]/#{radio_input_xpath}"
    ]
  end

  sig { params(value: T::Boolean).void }
  def click_radio_in_pass_fail_div(value)
    within ".pass-fail" do
      text_pattern = value ? /^(Yes|Pass)$/ : /^(No|Fail)$/
      find("label", text: text_pattern).find("input[type='radio']").click
    end
  end

  sig { params(label: String, value: T.any(T::Boolean, String)).void }
  def find_and_click_radio(label, value)
    # Convert value to the text that appears on the radio button label
    target_text = case value.to_s
    when "pass" then "Pass"
    when "fail" then "Fail"
    when "na" then "Not Applicable"
    else
      # Fallback for boolean values
      radio_text_for_boolean value, :pass_fail
    end

    # Find the form section containing the field label
    # Try both radio-comment and number-radio-comment containers
    xpath = "//div[contains(@class, 'form-grid') and " \
            "(contains(@class, 'radio-comment') or " \
            "contains(@class, 'number-radio-comment'))]" \
            "[.//label[@class='label'][normalize-space(.)='#{label}']]"

    within :xpath, xpath do
      # Find the pass-fail div, then the radio button with the target text
      within ".pass-fail" do
        text_regex = /^#{Regexp.escape target_text}$/
        find("label", text: text_regex).find("input[type='radio']").click
      end
    end
  end

  sig { params(label: String, value: T.any(T::Boolean, String), radio_value: String).returns T::Boolean }
  def try_radio_selectors(label, value, radio_value)
    build_radio_selectors(label, value, radio_value).each do |selector|
      find(:xpath, selector).click
      return true
    rescue Capybara::ElementNotFound
      next
    end
    false
  end

  sig { params(label: String, value: T.any(T::Boolean, String), radio_value: String).returns T::Array[String] }
  def build_radio_selectors(label, value, radio_value)
    pass_fail_text = radio_text_for_boolean value, :pass_fail

    [
      # Original selector for simple radio button structures
      build_simple_radio_selector(label, pass_fail_text),
      # For complex forms with pass-fail div
      build_complex_form_selector(label, radio_value),
      # For number-pass-fail-na forms
      build_partial_label_selector(label, radio_value),
      # Fallback selectors
      build_fallback_selector(label, radio_value),
      build_fallback_selector(label, value)
    ]
  end

  sig { params(label: String, text: String).returns String }
  def build_simple_radio_selector(label, text)
    "#{label_xpath label}/following::label[contains(.,'#{text}')][1]/" \
    "#{radio_input_xpath}"
  end

  sig { params(label: String, radio_value: String).returns String }
  def build_complex_form_selector(label, radio_value)
    "#{div_with_label_xpath label}//#{pass_fail_div_xpath}//" \
    "#{radio_input_xpath radio_value}"
  end

  sig { params(label: String, radio_value: String).returns String }
  def build_partial_label_selector(label, radio_value)
    first_word = label.split.first
    "//div[.//label[contains(.,'#{first_word}')]]//#{pass_fail_div_xpath}//" \
    "#{radio_input_xpath radio_value}"
  end

  sig { params(label: String, value: T.any(T::Boolean, String)).returns String }
  def build_fallback_selector(label, value)
    "#{div_with_label_xpath label}//#{radio_input_xpath value}"
  end

  sig { params(field_label: String, block: T.proc.params(field: Symbol, model: Symbol).returns(T.untyped)).returns T.untyped }
  def find_field_by_label(field_label, &block)
    BOOLEANS_BY_FORM.each do |model, fields|
      form_type = (model == :inspection) ? :inspection : :slide
      fields.each do |field|
        i18n_key = "forms.#{form_type}.fields.#{field}"
        return yield field, model if field_label == I18n.t(i18n_key)
      end
    end
    raise "Unknown field label: #{field_label}"
  end
end

RSpec.configure do |config|
  config.include RadioButtonHelpers, type: :feature
end
