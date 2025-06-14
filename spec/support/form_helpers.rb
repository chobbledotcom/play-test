module FormHelpers
  # Fill in a form field using standardized i18n keys
  # Usage: fill_in_form :units, :name, "Test Unit"
  # Translates to: forms.units.fields.name
  def fill_in_form(form_name, field_name, value)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    fill_in field_label, with: value
  end

  # Submit a form using standardized i18n keys
  # Usage: submit_form :units
  # Translates to: forms.units.submit
  def submit_form(form_name)
    submit_text = I18n.t("forms.#{form_name}.submit")
    click_button submit_text
  end

  # Check a checkbox in a form
  # Usage: check_form :units, :has_slide
  # Translates to: forms.units.fields.has_slide
  def check_form(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    check field_label
  end

  # Uncheck a checkbox in a form
  # Usage: uncheck_form :units, :has_slide
  def uncheck_form(form_name, field_name)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    uncheck field_label
  end

  # Checks that all expected i18n keys are present in the rendered form
  # by looking for the translated text on the page
  def expect_form_sections_present(i18n_base)
    # Get the sections from the i18n file
    sections = I18n.t("#{i18n_base}.sections", raise: true)

    sections.each do |key, translation|
      expect(page).to have_content(translation),
        "Expected to find section '#{key}' with text '#{translation}' on the page"
    end
  rescue I18n::MissingTranslationData
    raise "Missing i18n key: #{i18n_base}.sections - every form must define its sections"
  end

  # Checks for all fields defined in the i18n fields namespace
  def expect_form_fields_present(i18n_base)
    # Get all fields from the i18n file
    fields = I18n.t("#{i18n_base}.fields", raise: true)

    # Check if any pass/fail fields exist
    has_pass_fail_fields = fields.keys.any? { |k| k.to_s.end_with?("_pass") }

    # Check if any comment fields exist
    has_comment_fields = fields.keys.any? { |k| k.to_s.end_with?("_comment") }

    # If there are pass/fail fields, ensure the generic Pass and Fail labels are present
    if has_pass_fail_fields
      pass_label = I18n.t("shared.pass")
      fail_label = I18n.t("shared.fail")
      expect(page).to have_content(pass_label),
        "Expected to find generic Pass label '#{pass_label}' on the page"
      expect(page).to have_content(fail_label),
        "Expected to find generic Fail label '#{fail_label}' on the page"
    end

    # If there are comment fields, ensure the generic Comment label is present
    if has_comment_fields
      generic_comment_label = I18n.t("shared.comment")
      expect(page).to have_content(generic_comment_label),
        "Expected to find generic Comment label '#{generic_comment_label}' on the page"
    end

    fields.each do |field_key, field_label|
      # Skip pass/fail fields - they use generic Pass/Fail labels
      next if field_key.to_s.end_with?("_pass")

      # Check if the field label is on the page
      expect(page).to have_content(field_label),
        "Expected to find field '#{field_key}' with label '#{field_label}' on the page"
    end
  rescue I18n::MissingTranslationData
    raise "Missing i18n key: #{i18n_base}.fields - every form must define its fields"
  end

  # Comprehensive check that verifies all form elements match i18n structure
  def expect_form_matches_i18n(i18n_base)
    # Check header if present
    header = I18n.t("#{i18n_base}.header", default: nil)
    expect(page).to have_content(header) if header

    # Check all sections are present
    expect_form_sections_present(i18n_base)

    # Check all fields are present
    expect_form_fields_present(i18n_base)

    # Check fieldset structure matches sections
    expect_form_has_fieldsets(i18n_base)
  end

  # Helper to check if all fields in a form have corresponding i18n entries
  def verify_all_form_fields_have_i18n(form_selector, i18n_base)
    within(form_selector) do
      # Find all input fields with labels
      all("label").each do |label|
        label_text = label.text.strip
        next if label_text.empty?

        # Check if this label text exists in our i18n
        found = false
        I18n.t(i18n_base).each do |key, value|
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

  # Check for form errors using standardized i18n keys
  # Usage: expect_form_errors :units, count: 2
  def expect_form_errors(form_name, count: nil)
    if count
      error_header = I18n.t("forms.#{form_name}.errors.header", count: count)
      expect(page).to have_content(error_header)
    end
    expect(page).to have_css(".form-errors")
  end

  # Check that form has proper fieldset structure
  # Usage: expect_form_has_fieldsets("forms.inspector_companies")
  def expect_form_has_fieldsets(i18n_base)
    expect(page).to have_css("fieldset")

    # Check each section defined in the form's i18n has a corresponding fieldset
    sections = I18n.t("#{i18n_base}.sections", raise: true)
    sections.each do |_key, legend_text|
      expect(page).to have_css("fieldset legend", text: legend_text)
    end
  end

  # Click an assessment tab by tab name
  # Usage: click_assessment_tab("user_height")
  def click_assessment_tab(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    click_link tab_text
  end

  # Check that an assessment tab is visible
  # Usage: expect_assessment_tab("user_height")
  def expect_assessment_tab(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    expect(page).to have_link(tab_text)
  end

  # Check that an assessment tab is not visible
  # Usage: expect_no_assessment_tab("enclosed")
  def expect_no_assessment_tab(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    expect(page).not_to have_link(tab_text)
  end

  # Check that an assessment tab is active (current)
  # Usage: expect_assessment_tab_active("inspections")
  def expect_assessment_tab_active(tab_name)
    tab_text = I18n.t("forms.#{tab_name}.header")
    expect(page).to have_css("nav.tabs span", text: tab_text)
  end
end

RSpec.configure do |config|
  config.include FormHelpers, type: :feature
  config.include FormHelpers, type: :request
end
