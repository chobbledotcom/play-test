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

  # Removed - consolidated with other method_missing below

  def within_result(type, &block)
    within("##{RESULT_IDS[type]}", &block)
  end

  private

  # Dynamic expect methods

  # Dynamic method handler
  def method_missing(method, *args, **kwargs)
    method_str = method.to_s
    if method_str.start_with?("fill_")
      handle_fill_methods(method_str, **kwargs)
    elsif method_str.start_with?("submit_")
      nil  # No-op
    elsif method_str.start_with?("expect_")
      handle_expect_methods(method_str, *args, **kwargs)
    elsif method_str.start_with?("navigate_to_")
      handle_navigate_methods(method_str, args[0])
    else
      super
    end
  end

  private

  def handle_fill_methods(method_str, **fields)
    type = case method_str
    when /^fill_anchor_(form|calculator)$/
      :anchors
    when /^fill_runout_form$/
      :slide_runout
    when /^fill_slide_calculator$/
      :slide_runout
    when /^fill_wall_height_(form|calculator)$/
      :wall_height
    end

    fill_form_and_submit(type, fields) if type
  end

  def fill_form_and_submit(type, fields)
    form_name = :"safety_standards_#{type}"
    within_form(form_name) do
      fields.each do |field, value|
        fill_in_form(form_name, field, value)
      end
      submit_form(form_name)
    end
  end

  def handle_expect_methods(method_str, *args, **kwargs)
    case method_str
    when /^expect_anchor_result$/
      expect_calculator_result(:anchors, value: args[0])
    when /^expect_anchor_result_header$/
      expect_calculator_result(:anchors, value: args[0], format: :header)
    when /^expect_(runout|wall_height)_result$/
      handle_other_expect_result($1, *args, **kwargs)
    end
  end

  def handle_other_expect_result(type_str, *args, **kwargs)
    value = kwargs[:required_runout] || args[0]
    type = (type_str == "runout") ? :runout : :wall_height
    if type == :wall_height && value.is_a?(String) && value.match?(/\d+\.\d+m/)
      value = value.match(/(\d+\.\d+)/)[1]
    end
    expect_calculator_result(type, value: value)
  end

  def handle_navigate_methods(method_str, tab)
    case method_str
    when /^navigate_to_standard_tab$/
      navigate_to_tab(tab, type: :standard)
    when /^navigate_to_assessment_tab$/
      navigate_to_tab(tab, type: :assessment)
    end
  end

  public

  def respond_to_missing?(method, include_private = false)
    patterns = [
      /^(fill|submit)_(anchor|runout|wall_height)_(form|calculator)$/,
      /^expect_(anchor|runout|wall_height)_result(_header)?$/,
      /^navigate_to_(standard|assessment)_tab$/
    ]
    patterns.any? { |p| method.to_s.match?(p) } || super
  end

  # Removed - handled by method_missing

  # Generic navigation helper
  def navigate_to_tab(tab, type: :standard)
    case type
    when :standard
      tab_text = tab.is_a?(Symbol) ?
        tab.to_s.split("_").map(&:capitalize).join(" ") :
        tab
      click_link tab_text
    when :assessment
      click_i18n_link("forms.#{tab}.header")
    end
  end

  # Removed - use navigate_to_tab directly

  # Content expectation helpers
  def expect_tab_content(tab_id, *content_keys)
    within("##{tab_id}") do
      content_keys.each do |key|
        if key.is_a?(Symbol)
          expect_i18n_content("safety_standards.#{key}")
        else
          expect(page).to have_content(key)
        end
      end
    end
  end

  def expect_calculator_title(type)
    key = "safety_standards.calculators.#{type}.title"
    expect_i18n_content(key)
  end

  def expect_tab_links(*tabs)
    within("#safety-standard-tabs") do
      tabs.each do |tab|
        href = "##{tab.to_s.dasherize}"
        label = tab.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_link(label, href: href)
      end
    end
  end

  # Tab content expectations using data structure
  TAB_CONTENT = {
    material: ["Material Requirements", "Fabric", "Thread", "Rope", "Netting"],
    fan: ["Electrical Safety Requirements", "Grounding Test Weights"]
  }.freeze

  def expect_standard_tab_content(tab)
    if TAB_CONTENT[tab]
      expect_tab_content(tab.to_s, *TAB_CONTENT[tab])
    elsif tab == :slides
      within("#slides") do
        expect_calculator_title(:runout)
        expect_calculator_title(:wall_height)
        key = "safety_standards.wall_heights.requirements_by_platform"
        expect_i18n_content(key)
      end
    end
  end

  # Shortcuts for backward compatibility
  def expect_material_content
    expect_standard_tab_content(:material)
  end

  def expect_fan_content
    expect_standard_tab_content(:fan)
  end

  def expect_slides_content
    expect_standard_tab_content(:slides)
  end

  # Specific result expectations
  # Generic breakdown expectation helper
  def expect_breakdown(type, **options)
    within_result(type) do
      case type
      when :anchors
        expect_anchor_breakdown_content(**options)
      when :runout
        expect_runout_breakdown_content(**options)
      when :wall_height
        expect_wall_height_breakdown_content(**options)
      end
    end
  end

  private

  def expect_anchor_breakdown_content(width:, height:, area:)
    key = "safety_standards.calculators.anchor.front_back_area_label"
    area_label = I18n.t(key)
    expect(page).to have_content(area_label)
    area_text = "#{width}m (W) × #{height}m (H) = #{area}m²"
    expect(page).to have_content(area_text)
  end

  def expect_runout_breakdown_content(platform_height:, calculated:)
    calc_key = "safety_standards.calculators.runout.calculation_label"
    calc_label = I18n.t(calc_key)
    min_key = "safety_standards.calculators.runout.minimum_label"
    min_label = I18n.t(min_key)
    calc_text = "#{calc_label}: #{platform_height}m × 0.5 = #{calculated}m"
    expect(page).to have_content(calc_text)
    expect(page).to have_content("#{min_label}: 0.3m (300mm)")
  end

  def expect_wall_height_breakdown_content(
    height: nil, range: nil, calculation: nil, roof: false, no_walls: false
  )
    if no_walls
      expect(page).to have_content("Required Wall Height: 0.0m")
      expect(page).to have_content("No containing walls required")
    else
      expect(page).to have_content("Required Wall Height: #{height}m")
      expect(page).to have_content(range)
      expect(page).to have_content(calculation)
      expect(page).to have_content("Permanent roof required") if roof
    end
  end

  public

  # Shortcuts for backward compatibility
  def expect_anchor_breakdown(**opts)
    expect_breakdown(:anchors, **opts)
  end

  def expect_runout_breakdown(**opts)
    expect_breakdown(:runout, **opts)
  end

  def expect_wall_height_breakdown(**opts)
    expect_breakdown(:wall_height, **opts)
  end

  def expect_no_walls_required
    expect_breakdown(:wall_height, no_walls: true)
  end

  def expect_calculation_transparency
    expect(page).to have_content("((Area × 114.0 × 1.5) ÷ 1600.0)")
    expect(page).to have_content("50% of platform height, minimum 300mm")
    expect(page).to have_content("Ruby Source Code")
    expect(page).to have_content("Method: calculate_required_anchors")
    source = "Source: EN14960::Calculators::AnchorCalculator"
    expect(page).to have_content(source)
  end
end

RSpec.configure do |config|
  config.include SafetyStandardsTestHelpers, type: :feature
end
