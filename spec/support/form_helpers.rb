# typed: false
# frozen_string_literal: true

module FormHelpers
  # Load form YAML configuration with fully symbolized keys
  # Returns the full YAML content with all keys symbolized
  def get_form_config(path)
    yaml_content = YAML.load_file(path).deep_symbolize_keys!
    # Fields now have symbols directly in YAML, no conversion needed
    yaml_content
  end

  def fill_in_form(form_name, field_name, value)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    fill_in field_label, with: value
  end

  def within_form(form_name, &block)
    form_header = I18n.t("forms.#{form_name}.header")
    within(".calculator-form", text: form_header, &block)
  end

  def fill_in_form_within(form_name, field_name, value)
    within_form(form_name) do
      fill_in_form(form_name, field_name, value)
    end
  end

  def submit_form(form_name)
    submit_text = I18n.t("forms.#{form_name}.submit")
    # Try both button texts - the original and "Save & Continue"
    begin
      click_button submit_text
    rescue Capybara::ElementNotFound
      click_button "Save & Continue"
    end
  end

  def submit_form_within(form_name)
    within_form(form_name) do
      submit_form(form_name)
    end
  end

  def check_form(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    check field_label
  end

  def uncheck_form(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    uncheck field_label
  end

  def check_form_radio(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    check_radio field_label
  end

  def uncheck_form_radio(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    uncheck_radio field_label
  end

  def find_form_field(form_name, field_name)
    expect_field_present(form_name, field_name)
    find_field(I18n.t("forms.#{form_name}.fields.#{field_name}"))
  end

  def expect_field_present(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    expect(page).to have_field(field_label)
  end

  def expect_field_not_present(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    expect(page).not_to have_field(field_label)
  end

  def expect_form_sections_present(i18n_base)
    sections = I18n.t("#{i18n_base}.sections", raise: true)

    sections.each do |key, translation|
      expect(page).to have_content(translation),
        "Expected to find section '#{key}' with text '#{translation}' on the page"
    end
  rescue I18n::MissingTranslationData
    raise "Missing i18n key: #{i18n_base}.sections - every form must define its sections"
  end

  def expect_form_fields_present(i18n_base)
    fields = I18n.t("#{i18n_base}.fields", raise: true)

    has_pass_fail_fields = fields.keys.any? { |k| k.to_s.end_with?("_pass") }

    has_comment_fields = fields.keys.any? { |k| k.to_s.end_with?("_comment") }

    if has_pass_fail_fields
      pass_label = I18n.t("shared.pass")
      fail_label = I18n.t("shared.fail")
      expect(page).to have_content(pass_label),
        "Expected to find generic Pass label '#{pass_label}' on the page"
      expect(page).to have_content(fail_label),
        "Expected to find generic Fail label '#{fail_label}' on the page"
    end

    if has_comment_fields
      generic_comment_label = I18n.t("shared.comment")
      expect(page).to have_content(generic_comment_label),
        "Expected to find generic Comment label '#{generic_comment_label}' on the page"
    end

    fields.each do |field_key, field_label|
      next if field_key.to_s.end_with?("_pass") || field_key.to_s == "id"

      expect(page).to have_content(field_label),
        "Expected to find field '#{field_key}' with label '#{field_label}' on the page"
    end
  rescue I18n::MissingTranslationData
    raise "Missing i18n key: #{i18n_base}.fields - every form must define its fields"
  end

  def expect_form_matches_i18n(i18n_base)
    header = I18n.t("#{i18n_base}.header", default: nil)
    expect(page).to have_content(header) if header

    expect_form_sections_present(i18n_base)

    expect_form_fields_present(i18n_base)

    expect_form_has_fieldsets(i18n_base)
  end

  def verify_all_form_fields_have_i18n(form_selector, i18n_base)
    within(form_selector) do
      all("label").each do |label|
        label_text = label.text.strip
        next if label_text.empty?

        found = false
        I18n.t(i18n_base).each_value do |value|
          if value.is_a?(String) && value == label_text
            found = true
            break
          end
        end

        expect(found).to be true,
          "Form label '#{label_text}' does not have a corresponding i18n entry in #{i18n_base}"
      end
    end
  end

  def expect_form_errors(form_name, count: nil)
    if count
      error_header = I18n.t("forms.#{form_name}.errors.header", count: count)
      expect(page).to have_content(error_header)
    end
    expect(page).to have_css(".form-errors")
  end

  def expect_form_has_fieldsets(i18n_base)
    expect(page).to have_css("fieldset")

    sections = I18n.t("#{i18n_base}.sections", raise: true)
    sections.each_value do |legend_text|
      expect(page).to have_css("fieldset legend", text: legend_text)
    end
  end

  def click_assessment_tab(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    click_link tab_text
  end

  def expect_assessment_tab(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    expect(page).to have_link(tab_text)
  end

  def expect_no_assessment_tab(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    expect(page).not_to have_link(tab_text)
  end

  def expect_assessment_tab_active(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    expect(page).to have_css("nav#tabs span", text: tab_text)
  end

  # Generic I18n helpers
  def click_i18n_button(key, **interpolations)
    button_text = I18n.t(key, **interpolations)
    # Try both button texts - the original and "Save & Continue"
    begin
      click_button button_text
    rescue Capybara::ElementNotFound
      click_button "Save & Continue"
    end
  end

  def expect_i18n_content(key, **interpolations)
    expect(page).to have_content(I18n.t(key, **interpolations))
  end

  def click_i18n_link(key, **interpolations)
    click_link I18n.t(key, **interpolations)
  end

  # Smart field filling that handles all field types
  def smart_fill_field(form_name, field_name, value)
    field_str = field_name.to_s

    # Skip comment fields entirely - matching original behavior
    return if field_str.end_with?("_comment")

    case value
    when true, false
      if field_str.end_with?("_pass") || field_str == "passed"
        field_label = get_field_label(form_name, field_name)
        choose_pass_fail(field_label, value)
      elsif %w[has_slide is_totally_enclosed passed slide_permanent_roof].include?(field_str)
        if value
          check_form_radio(form_name.to_sym, field_name)
        else
          uncheck_form_radio(form_name.to_sym, field_name)
        end
      else
        field_label = get_field_label(form_name, field_name)
        choose_yes_no(field_label, value)
      end
    when nil, ""
      # Skip nil or empty values
    else
      fill_in_form(form_name.to_sym, field_name, value)
    end
  end

  def get_field_label(form_name, field_name)
    field_str = field_name.to_s

    if field_str.end_with?("_pass")
      pass_key = "forms.#{form_name}.fields.#{field_name}"
      base_key = "forms.#{form_name}.fields.#{field_str.chomp("_pass")}"

      I18n.exists?(pass_key) ? I18n.t(pass_key) : I18n.t(base_key)
    else
      I18n.t("forms.#{form_name}.fields.#{field_name}")
    end
  end

  # Assessment helpers
  def fill_assessment_form(assessment_type, data)
    data.each do |field_name, value|
      smart_fill_field(assessment_type, field_name, value)
    end
  end

  def expect_assessment_complete(inspection, assessment_type)
    if assessment_type == "results"
      expect(inspection.reload.passed).to be true
    else
      assessment = inspection.reload.send("#{assessment_type}_assessment")
      expect(assessment.complete?).to be true
    end
  end

  def fill_comment_field(form_name, field_name, value)
    # Comment fields use a checkbox toggle pattern
    # First, check the comment checkbox to show the field
    checkbox = find("input[type='checkbox'][data-comment-toggle='#{form_name}_#{field_name}']")
    checkbox.check unless checkbox.checked?

    # Then fill in the text field
    text_field_id = "#{form_name}_#{field_name}"
    fill_in text_field_id, with: value
  end

  def expect_assessment_check_mark(tab_name, has_check: true)
    tab_text = I18n.t("forms.#{tab_name}.header")

    within("nav#tabs") do
      if has_check
        if page.has_css?("span", text: tab_text)
          expect(page).to have_css("span", text: "#{tab_text} ✓")
        else
          expect(page).to have_link("#{tab_text} ✓")
        end
      elsif page.has_css?("span", text: tab_text)
        expect(page).to have_css("span", text: tab_text)
        expect(page).not_to have_css("span", text: "#{tab_text} ✓")
      else
        expect(page).to have_link(tab_text)
        expect(page).not_to have_link("#{tab_text} ✓")
      end
    end
  end

  # User/Unit creation helpers
  def create_and_register_user(user_data, activate: false)
    visit root_path
    click_i18n_link("users.titles.register")

    user_data.each do |field_name, value|
      fill_in_form :user_new, field_name, value
    end

    submit_form :user_new

    user = User.find_by!(email: user_data[:email])
    user.update!(active_until: 5.minutes.from_now) if activate
    user
  end

  def create_unit_via_ui(name:, **attributes)
    visit units_path
    click_i18n_button("units.buttons.add_unit")

    attributes.merge(name: name).each do |field_name, value|
      fill_in_form :units, field_name, value
    end

    submit_form :units
    expect_i18n_content("units.messages.created")

    Unit.find_by!(name: name)
  end

  def create_inspection_via_ui(unit)
    visit unit_path(unit)
    # Accept the confirmation dialog when clicking Add Inspection
    accept_confirm(I18n.t("units.messages.add_inspection_confirm")) do
      click_i18n_button("units.buttons.add_inspection")
    end
    unit.inspections.order(created_at: :desc).first
  end
end

RSpec.configure do |config|
  config.include FormHelpers, type: :feature
  config.include FormHelpers, type: :request
end
