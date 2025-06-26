module SafetyStandardsTestHelpers
  FORM_TYPES = {
    anchors: "safety_standards_anchors",
    runout: "safety_standards_slide_runout",
    wall_height: "safety_standards_wall_height"
  }.freeze

  RESULT_IDS = {
    anchors: "anchors-result",
    runout: "slide-runout-result",
    wall_height: "wall-height-result"
  }.freeze

  def fill_calculator_form(type, **fields)
    form_name = FORM_TYPES[type]
    fields.each do |field, value|
      fill_in_form_within(form_name, field, value)
    end
  end

  def submit_calculator_form(type)
    submit_form_within(FORM_TYPES[type])
  end

  def fill_anchor_form(length:, width:, height:)
    fill_calculator_form(:anchors, length: length, width: width, height: height)
  end

  def fill_runout_form(height:)
    fill_calculator_form(:runout, platform_height: height)
  end

  def fill_wall_height_form(height: nil, platform_height: nil, user_height: nil)
    # Support both old signature (height:) and new signature (platform_height:, user_height:)
    if height && !platform_height && !user_height
      # Old signature - assume reasonable defaults
      fill_calculator_form(:wall_height, platform_height: 2.0, user_height: height)
    else
      fill_calculator_form(:wall_height, platform_height: platform_height, user_height: user_height)
    end
  end

  def submit_anchor_form = submit_calculator_form(:anchors)

  def submit_runout_form = submit_calculator_form(:runout)

  def submit_wall_height_form = submit_calculator_form(:wall_height)

  def within_result(type, &block)
    within("##{RESULT_IDS[type]}", &block)
  end

  def expect_result_content(type, content)
    within_result(type) { expect(page).to have_content(content) }
  end

  def expect_anchor_result(count)
    expect_result_content(:anchors, "Required Anchors: #{count}")
  end

  def expect_runout_result(required_runout:)
    expect_result_content(:runout, "Required Runout: #{required_runout}m")
  end

  def expect_wall_height_result(text)
    expect_result_content(:wall_height, text)
  end

  # Navigation helpers
  def navigate_to_tab(tab_name)
    click_link tab_name
  end

  # Form validation helpers
  def expect_form_field_min_value(form_name, field_name, expected_min)
    within_form(form_name) do
      field = find_form_field(form_name, field_name)
      expect(field["min"]).to eq(expected_min)
    end
  end

  # Form persistence helpers
  def expect_form_values_persist(form_name, expected_values)
    within_form(form_name) do
      expected_values.each do |field_name, expected_value|
        field = find_form_field(form_name, field_name)
        expect(field.value).to eq(expected_value)
      end
    end
  end

  # Combined fill and submit helper
  def submit_form_with_values(type, values)
    case type
    when :anchors
      fill_anchor_form(**values)
      submit_anchor_form
    when :runout
      fill_runout_form(**values)
      submit_runout_form
    when :wall_height
      fill_wall_height_form(**values)
      submit_wall_height_form
    end
  end
end

RSpec.configure do |config|
  config.include SafetyStandardsTestHelpers, type: :feature
end
