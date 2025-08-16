# typed: false

RSpec.shared_examples "assessment form save" do |assessment_type, sample_data|
  describe "#{assessment_type} assessment form" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }
    let(:inspection) do
      options = {user: user, unit: unit}
      options[:has_slide] = true if assessment_type == :slide
      options.merge!(traits_for_assessment(assessment_type))
      create(:inspection, **options)
    end

    before { sign_in(user) }

    it "saves all #{assessment_type} assessment fields correctly" do
      visit_assessment_tab(assessment_type)
      fill_assessment_fields(assessment_type, sample_data)
      submit_and_verify(assessment_type, sample_data)
    end

    private

    define_method(:traits_for_assessment) do |type|
      (type == :enclosed) ? {is_totally_enclosed: true} : {}
    end

    define_method(:visit_assessment_tab) do |type|
      tab = (type == :user_height) ? "user_height" : type.to_s
      visit edit_inspection_path(inspection, tab: tab)
    end

    define_method(:fill_assessment_fields) do |type, data|
      i18n_base = "forms.#{type}"
      fields = I18n.t("#{i18n_base}.fields")

      data.each do |field_key, value|
        next if skip_field?(field_key, data)

        validate_field_exists(field_key, fields, i18n_base)
        fill_field(field_key, value, fields, data)
      end
    end

    define_method(:submit_and_verify) do |type, data|
      submit_form type
      expect_updated_message
      verify_saved_values(inspection, type, data)
    end

    define_method(:skip_field?) do |field_key, data|
      return false unless field_key.to_s.end_with?("_pass")

      base_key = field_key.to_s.chomp("_pass").to_sym
      data.key?(base_key) && data[base_key].is_a?(Numeric)
    end

    define_method(:validate_field_exists) do |field_key, fields, i18n_base|
      return if field_key.to_s.end_with?("_comment")

      # Always use base field name for i18n lookup
      lookup_key = ChobbleForms::FieldUtils.strip_field_suffix(field_key).to_sym
      return if fields.key?(lookup_key)

      raise "Field #{lookup_key} missing from #{i18n_base}.fields.#{lookup_key}"
    end

    define_method(:fill_field) do |field_key, value, fields, data|
      # Always use base field name for i18n lookup
      lookup_key = ChobbleForms::FieldUtils.strip_field_suffix(field_key).to_sym
      field_label = fields[lookup_key]

      case value
      when true, false
        fill_boolean_field(field_key, value, field_label, data)
      when Numeric
        fill_numeric_field(field_key, value, field_label, data)
      when String
        if enum_pass_field?(field_key, value)
          find_and_click_radio(field_label, value)
        else
          fill_string_field(field_key, value, fields)
        end
      end
    end

    define_method(:fill_boolean_field) do |field_key, value, label, data|
      pass_key = :"#{field_key}_pass"

      if data.key?(pass_key)
        fill_in label, with: value.to_s
        choose_pass_fail(label, data[pass_key])
      else
        choose_yes_no(label, value)
      end
    end

    define_method(:fill_numeric_field) do |field_key, value, label, data|
      fill_in label, with: value.to_s

      pass_key = :"#{field_key}_pass"
      choose_pass_fail(label, data[pass_key]) if data.key?(pass_key)
    end

    define_method(:fill_string_field) do |field_key, value, fields|
      if field_key.to_s.end_with?("_comment")
        fill_comment_field(field_key, value, fields)
      else
        fill_in fields[field_key], with: value
      end
    end

    define_method(:fill_comment_field) do |field_key, value, fields|
      base_key = field_key.to_s.chomp("_comment").to_sym
      base_label = fields[base_key]

      if base_label
        fill_comment_in_context(base_key, base_label, value)
      else
        fill_comment_directly(base_key, value)
      end
    end

    define_method(:enum_pass_field?) do |field_key, value|
      field_key.to_s.end_with?("_pass") && %w[pass fail na].include?(value)
    end

    define_method(:fill_comment_directly) do |base_key, value|
      checkbox = find(:css, "input[type='checkbox'][id*='#{base_key}_has_comment_']")
      checkbox.check unless checkbox.checked?

      textarea = find(:css, "textarea[id*='#{base_key}_comment_']", visible: :all)
      textarea.set(value)
    end

    define_method(:fill_comment_in_context) do |base_key, base_label, value|
      containers = ["form-grid", "radio-comment", "number-radio-comment"]
      filled = false

      containers.each do |container|
        xpath = "//div[contains(@class, '#{container}')]"
        xpath += "[.//label[normalize-space(.)='#{base_label}']]"

        begin
          within(:xpath, xpath) do
            checkbox = find(:css, "input[type='checkbox'][id*='_has_comment_']")
            checkbox.check unless checkbox.checked?

            textarea = find(:css, "textarea[id*='_comment_']", visible: :all)
            textarea.set(value)
          end
          filled = true
          break
        rescue Capybara::ElementNotFound
          next
        end
      end

      fill_comment_directly(base_key, value) unless filled
    end

    define_method(:verify_saved_values) do |inspection, assessment_type, sample_data|
      inspection.reload
      assessment = inspection.send("#{assessment_type}_assessment")

      sample_data.each do |field_key, expected|
        actual = assessment.send(field_key)
        expect(actual).to eq(expected),
          "#{field_key}: expected #{expected.inspect}, got #{actual.inspect}"
      end
    end
  end
end
