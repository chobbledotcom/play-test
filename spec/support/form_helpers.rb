module FormHelpers
  def fill_in_form(form_name, field_name, value)
    field_label = I18n.t("forms.#{form_name}.fields.#{field_name}")
    fill_in field_label, with: value
  end

  def submit_form(form_name)
    submit_text = I18n.t("forms.#{form_name}.submit")
    click_button submit_text
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
      next if field_key.to_s.end_with?("_pass")

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
    sections.each do |_key, legend_text|
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
    expect(page).to have_css("nav.tabs span", text: tab_text)
  end
end

RSpec.configure do |config|
  config.include FormHelpers, type: :feature
  config.include FormHelpers, type: :request
end
