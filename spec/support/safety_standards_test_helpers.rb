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

  def fill_wall_height_form(height:)
    fill_calculator_form(:wall_height, user_height: height)
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
end

RSpec.configure do |config|
  config.include SafetyStandardsTestHelpers, type: :feature
end
