module SafetyStandardsTestHelpers
  FORM_TYPES = {
    anchors: "safety_standards_anchors",
    capacity: "safety_standards_user_capacity",
    runout: "safety_standards_slide_runout",
    wall_height: "safety_standards_wall_height"
  }.freeze

  RESULT_IDS = {
    anchors: "anchors-result",
    capacity: "user-capacity-result",
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

  def fill_capacity_form(length:, width:, adjustment: 0)
    fill_calculator_form(:capacity, length: length, width: width, negative_adjustment: adjustment)
  end

  def fill_runout_form(height:)
    fill_calculator_form(:runout, platform_height: height)
  end

  def fill_wall_height_form(height:)
    fill_calculator_form(:wall_height, user_height: height)
  end

  def submit_anchor_form = submit_calculator_form(:anchors)
  def submit_capacity_form = submit_calculator_form(:capacity)
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

  def expect_capacity_result(usable_area:)
    expect_result_content(:capacity, "Usable Area: #{usable_area}m²")
  end

  def expect_runout_result(required_runout:)
    expect_result_content(:runout, "Required Runout: #{required_runout}m")
  end

  def expect_wall_height_result(text)
    expect_result_content(:wall_height, text)
  end

  def expect_capacity_details(length:, width:, adjustment:)
    expected = SafetyStandard.calculate_user_capacity(length, width, adjustment)
    area = length * width
    
    within_result(:capacity) do
      expect(page).to have_content("Dimensions: #{length}m × #{width}m")
      expect(page).to have_content("Total Area: #{area}m²")
      expect(page).to have_content("Negative Adjustment: -#{adjustment}m²") if adjustment > 0
      
      %i[users_1000mm users_1200mm users_1500mm users_1800mm].zip(
        ["young children", "children", "adolescents", "adults"],
        ["1.0m", "1.2m", "1.5m", "1.8m"]
      ).each do |key, age_group, height|
        expect(page).to have_content("#{height} users: #{expected[key]} (#{age_group})")
      end
    end
  end
end

RSpec.configure do |config|
  config.include SafetyStandardsTestHelpers, type: :feature
end