module ViewHelpers
  # Check for form field presence by name attribute
  # Usage: expect_form_field("inspector_company[name]")
  #        expect_form_field("user[email]", type: "email")
  def expect_form_field(field_name, type: nil)
    if type
      expect(rendered).to have_css("input[name='#{field_name}'][type='#{type}']")
    else
      expect(rendered).to include("name=\"#{field_name}\"")
    end
  end

  # Check for submit button using i18n or explicit text
  # Usage: expect_submit_button("forms.inspector_companies")
  #        expect_submit_button(text: "Save Changes")
  def expect_submit_button(i18n_base_or_options)
    text = if i18n_base_or_options.is_a?(Hash)
      i18n_base_or_options[:text]
    else
      I18n.t("#{i18n_base_or_options}.submit")
    end

    expect(rendered).to include('type="submit"')
    expect(rendered).to include(text)
  end

  # Check that field is pre-populated with specific value
  # Usage: expect_field_prepopulated("Company Name", "Acme Corp")
  #        expect_field_prepopulated("inspector_company[name]", company.name, by: :name)
  def expect_field_prepopulated(field_identifier, value, by: :label)
    case by
    when :label
      expect(rendered).to have_field(field_identifier, with: value)
    when :name
      # Check the field exists and contains the value (input or textarea)
      if rendered.match?(%r{<input[^>]*name=['"]#{Regexp.escape(field_identifier)}['"]})
        expect(rendered).to have_css("input[name='#{field_identifier}'][value='#{value}']")
      else
        expect(rendered).to have_css("textarea[name='#{field_identifier}']", text: value)
      end
    else
      raise ArgumentError, "Unknown selector type: #{by}"
    end
  end

  # Check for multiple validation errors
  # Usage: expect_validation_errors("Email is invalid", "Name can't be blank")
  def expect_validation_errors(*messages)
    messages.each do |message|
      expect(rendered).to include(message)
    end
  end

  # Common setup for admin user in view context
  # Usage: setup_admin_view_context
  def setup_admin_view_context(user = nil)
    admin_user = user || create(:user, :admin)
    allow(view).to receive(:current_user).and_return(admin_user)
    admin_user
  end

  # Check for i18n content in rendered view
  # Usage: expect_i18n_content("users.titles.register")
  def expect_i18n_content(i18n_key, options = {})
    translated_text = I18n.t(i18n_key, **options)
    expect(rendered).to have_content(translated_text)
  end

  # Check form has all expected fields from i18n structure
  # Usage: expect_form_fields_from_i18n("forms.inspector_companies")
  def expect_form_fields_from_i18n(i18n_base)
    fields = I18n.t("#{i18n_base}.fields", raise: true)

    fields.each do |field_key, field_label|
      # Just check the label is present - actual field testing is separate
      expect(rendered).to have_content(field_label),
        "Expected to find field label '#{field_label}' for field '#{field_key}'"
    end
  rescue I18n::MissingTranslationData
    raise "Missing i18n key: #{i18n_base}.fields - form must define its fields"
  end

  # Check form has all expected sections from i18n structure
  # Usage: expect_form_sections_from_i18n("forms.inspector_companies")
  def expect_form_sections_from_i18n(i18n_base)
    sections = I18n.t("#{i18n_base}.sections", default: {})

    sections.each do |_key, section_title|
      expect(rendered).to have_content(section_title)
    end
  end

  # Check for presence of specific HTML structure
  # Usage: expect_fieldset_with_legend("Company Details")
  def expect_fieldset_with_legend(legend_text)
    expect(rendered).to have_css("fieldset legend", text: legend_text)
  end

  # Check multiple form fields at once
  # Usage: expect_form_fields_present("user", %w[name email password])
  def expect_form_fields_present(model_name, field_names)
    field_names.each do |field|
      expect_form_field("#{model_name}[#{field}]")
    end
  end

  # Check that model's attributes are displayed (not in form fields)
  # Usage: expect_model_attributes_displayed(company, :name, :email, :phone)
  def expect_model_attributes_displayed(model, *attributes)
    attributes.each do |attr|
      value = model.send(attr)
      expect(rendered).to include(value.to_s) if value.present?
    end
  end

  # Mock form builder for partial specs
  # Usage: mock_form = mock_form_builder
  def mock_form_builder
    form = double("FormBuilder")

    # Common form builder methods
    %i[text_field email_field password_field text_area select check_box
      number_field telephone_field file_field hidden_field radio_button
      submit label].each do |method|
      allow(form).to receive(method).and_return("<#{method} />".html_safe)
    end

    form
  end

  # Setup standard form field configuration for partial specs
  # Usage: setup_form_field_config(field: :name, label: "Name")
  def setup_form_field_config(field:, label: nil, **options)
    i18n_base = options[:i18n_base] || "test.forms"
    config = {
      form_object: @mock_form || mock_form_builder,
      i18n_base: i18n_base,
      field_label: label || field.to_s.humanize,
      field_hint: options[:hint],
      field_placeholder: options[:placeholder]
    }

    allow(view).to receive(:form_field_setup).and_return(config)
    view.instance_variable_set(:@_current_i18n_base, i18n_base)

    config
  end

  # Setup mock form builder with specific field rendering
  # Usage: setup_mock_field(:text_field, :name, '<input type="text" />')
  def setup_mock_field(field_type, field_name, rendered_html)
    @mock_form ||= mock_form_builder
    allow(@mock_form).to receive(field_type)
      .with(field_name, anything)
      .and_return(rendered_html.html_safe)
  end

  # Setup standard label mock
  # Usage: setup_mock_label(:name, "Name")
  def setup_mock_label(field_name, label_text)
    @mock_form ||= mock_form_builder
    allow(@mock_form).to receive(:label)
      .with(field_name, anything)
      .and_return(%(<label for="#{field_name}">#{label_text}</label>).html_safe)
  end

  # Render a form partial with standard setup
  # Usage: render_form_partial("text_field", field: :name)
  def render_form_partial(partial_name, locals = {})
    render partial: "chobble_forms/#{partial_name}", locals: locals
  end

  # Check for labeled form field structure
  # Usage: expect_labeled_field(:name, "Name", type: "text")
  def expect_labeled_field(field_name, label_text, type: "text")
    expect(rendered).to have_css("label[for='#{field_name}']", text: label_text)
    expect(rendered).to have_css("input[type='#{type}'][name='#{field_name}'][id='#{field_name}']")
  end

  # Check form partial renders with correct field type
  # Usage: expect_field_type_rendered(:email_field, "email")
  def expect_field_type_rendered(field_method, input_type)
    expect(rendered).to have_css(%(input[type="#{input_type}"]))
  end

  # Check for action links/buttons
  # Usage: expect_action_link("Edit", href: edit_user_path(user))
  def expect_action_link(text, href: nil)
    if href
      expect(rendered).to have_link(text, href: href)
    else
      expect(rendered).to have_link(text)
    end
  end

  # Check for turbo-enabled links
  # Usage: expect_turbo_link("Delete", method: :delete, confirm: true)
  def expect_turbo_link(text, method: nil, confirm: false)
    link_selector = "a"
    link_selector += "[data-turbo-method='#{method}']" if method
    link_selector += "[data-turbo-confirm]" if confirm

    expect(rendered).to have_css(link_selector, text: text)
  end

  # Check form structure matches i18n conventions
  # Usage: expect_standard_form_structure("forms.inspector_companies")
  def expect_standard_form_structure(i18n_base)
    # Check header if defined
    header = I18n.t("#{i18n_base}.header", default: nil)
    expect_i18n_content("#{i18n_base}.header") if header

    # Check sections and fields
    expect_form_sections_from_i18n(i18n_base)
    expect_form_fields_from_i18n(i18n_base)

    # Check submit button
    expect_submit_button(i18n_base)
  end

  # Check for empty/non-populated password fields (security)
  # Usage: expect_password_fields_empty("user", %w[password password_confirmation])
  def expect_password_fields_empty(model_name, field_names)
    field_names.each do |field|
      field_name = "#{model_name}[#{field}]"
      # Password fields should exist but have no value
      expect(rendered).to have_css("input[name='#{field_name}'][type='password']")
      expect(rendered).not_to have_css("input[name='#{field_name}'][value]")
    end
  end

  # Check checkbox state
  # Usage: expect_checkbox_checked("user[active]")
  def expect_checkbox_checked(field_name, checked: true)
    if checked
      expect(rendered).to have_checked_field(name: field_name)
    else
      expect(rendered).to have_unchecked_field(name: field_name)
    end
  end

  # Check select field options
  # Usage: expect_select_options("user[role]", ["Admin", "User", "Guest"])
  def expect_select_options(field_name, options)
    select = find("select[name='#{field_name}']")
    actual_options = select.all("option").map(&:text)
    expect(actual_options).to match_array(options)
  end
end

RSpec.configure do |config|
  config.include ViewHelpers, type: :view
end
