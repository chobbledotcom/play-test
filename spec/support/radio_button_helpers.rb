module RadioButtonHelpers
  BOOLEANS_BY_FORM = {
    inspection: %i[has_slide is_totally_enclosed passed],
    slide_assessment: %i[slide_permanent_roof]
  }.freeze

  def choose_yes_no(field_label, value)
    choose_radio_in_container(field_label, value,
      ["radio-comment"],
      yes: ["yes", "pass"],
      no: ["no", "fail"])
  end

  def choose_pass_fail(field_label, value)
    find_and_click_radio(field_label, value)
  end

  def check_radio(field_label)
    choose_yes_no(field_label, true)
  end

  def uncheck_radio(field_label)
    choose_yes_no(field_label, false)
  end

  def field_label_to_field_name(field_label)
    find_field_by_label(field_label) { |field| field.to_s }
  end

  def field_label_to_name(field_label)
    find_field_by_label(field_label) { |field, model| "#{model}[#{field}]" }
  end

  private

  def choose_radio_in_container(label, value, containers, selectors)
    found = false

    # Try to find the radio button using the simplified HTML structure
    begin
      # First, try to find by the main label
      container = find(:xpath, "//div[@class='form-grid radio-comment'][.//label[@class='label'][normalize-space(.)='#{label}']]")

      # Then find the pass-fail div and click the appropriate radio
      within(container) do
        within(".pass-fail") do
          if value
            # Click Yes/Pass radio
            find("label", text: /^(Yes|Pass)$/).find("input[type='radio']").click
          else
            # Click No/Fail radio
            find("label", text: /^(No|Fail)$/).find("input[type='radio']").click
          end
        end
      end
      found = true
    rescue Capybara::ElementNotFound
      # Try alternative selectors if the first approach fails
      alt_selectors = [
        "//label[normalize-space(.)='#{label}']/following-sibling::div[@class='pass-fail']//label[contains(.,'#{value ? "Yes" : "No"}')]/input[@type='radio']",
        "//label[normalize-space(.)='#{label}']/following-sibling::div[@class='pass-fail']//label[contains(.,'#{value ? "Pass" : "Fail"}')]/input[@type='radio']"
      ]

      alt_selectors.each do |selector|
        find(:xpath, selector).click
        found = true
        break
      rescue Capybara::ElementNotFound
        next
      end
    end

    raise Capybara::ElementNotFound, "Unable to find radio for '#{label}'" unless found
  end

  def find_and_click_radio(label, value)
    # Convert boolean values to enum strings if needed
    radio_value = case value
    when true then "pass"
    when false then "fail"
    else value.to_s
    end

    selectors = [
      # Original selector for simple radio button structures
      "//label[normalize-space(.)='#{label}']/following::label[contains(.,'#{value ? "Pass" : "Fail"}')][1]/input[@type='radio']",
      # For complex forms: find div containing the label, then look for pass-fail div with radio buttons
      "//div[.//label[normalize-space(.)='#{label}']]//div[@class='pass-fail']//input[@type='radio'][@value='#{radio_value}']",
      # For number-pass-fail-na forms: find by base field label (e.g., "Ropes (mm)"), then find pass-fail div
      "//div[.//label[contains(.,'#{label.split.first}')]]//div[@class='pass-fail']//input[@type='radio'][@value='#{radio_value}']",
      # Fallback selectors
      "//div[.//label[normalize-space(.)='#{label}']]//input[@type='radio'][@value='#{radio_value}']",
      "//div[.//label[normalize-space(.)='#{label}']]//input[@type='radio'][@value='#{value}']"
    ]

    clicked = false
    selectors.each do |selector|
      find(:xpath, selector).click
      clicked = true
      break
    rescue Capybara::ElementNotFound
      next
    end

    return if clicked

    raise Capybara::ElementNotFound, "Unable to find radio for '#{label}'"
  end

  def find_field_by_label(field_label)
    BOOLEANS_BY_FORM.each do |model, fields|
      form_type = (model == :inspection) ? :inspection : :slide
      fields.each do |field|
        i18n_key = "forms.#{form_type}.fields.#{field}"
        return yield(field, model) if field_label == I18n.t(i18n_key)
      end
    end
    raise "Unknown field label: #{field_label}"
  end
end

RSpec.configure do |config|
  config.include RadioButtonHelpers, type: :feature
end
