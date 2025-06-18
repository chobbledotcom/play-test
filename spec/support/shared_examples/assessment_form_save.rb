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

    def traits_for_assessment(type)
      (type == :enclosed) ? {is_totally_enclosed: true} : {}
    end

    def visit_assessment_tab(type)
      tab = (type == :user_height) ? "user_height" : type.to_s
      visit edit_inspection_path(inspection, tab: tab)
    end

    def fill_assessment_fields(type, data)
      i18n_base = "forms.#{type}"
      fields = I18n.t("#{i18n_base}.fields")

      data.each do |field_key, value|
        next if skip_field?(field_key, data)

        validate_field_exists(field_key, fields, i18n_base)
        fill_field(field_key, value, fields, data)
      end
    end

    def submit_and_verify(type, data)
      click_button I18n.t("forms.#{type}.submit")
      expect_updated_message
      verify_saved_values(inspection, type, data)
    end

    def skip_field?(field_key, data)
      return false unless field_key.to_s.end_with?("_pass")

      base_key = field_key.to_s.chomp("_pass").to_sym
      data.key?(base_key) && data[base_key].is_a?(Numeric)
    end

    def validate_field_exists(field_key, fields, i18n_base)
      return if fields.key?(field_key) || field_key.to_s.end_with?("_comment")

      raise "Field #{field_key} missing from #{i18n_base}.fields.#{field_key}"
    end

    def fill_field(field_key, value, fields, data)
      field_label = fields[field_key]

      case value
      when true, false
        fill_boolean_field(field_key, value, field_label, data)
      when Numeric
        fill_numeric_field(field_key, value, field_label, data)
      when String
        fill_string_field(field_key, value, fields)
      end
    end

    def fill_boolean_field(field_key, value, label, data)
      pass_key = :"#{field_key}_pass"

      if data.key?(pass_key)
        fill_in label, with: value.to_s
        choose_pass_fail(label, data[pass_key])
      else
        choose_yes_no(label, value)
      end
    end

    def fill_numeric_field(field_key, value, label, data)
      fill_in label, with: value.to_s

      pass_key = :"#{field_key}_pass"
      choose_pass_fail(label, data[pass_key]) if data.key?(pass_key)
    end

    def fill_string_field(field_key, value, fields)
      if field_key.to_s.end_with?("_comment")
        fill_comment_field(field_key, value, fields)
      else
        fill_in fields[field_key], with: value
      end
    end

    def fill_comment_field(field_key, value, fields)
      base_key = field_key.to_s.chomp("_comment").to_sym
      base_label = fields[base_key]

      if base_label
        fill_comment_in_context(base_key, base_label, value)
      else
        fill_comment_directly(base_key, value)
      end
    end

    def fill_comment_directly(base_key, value)
      checkbox = find(:css, "input[type='checkbox'][id*='#{base_key}_has_comment_']")
      checkbox.check unless checkbox.checked?

      textarea = find(:css, "textarea[id*='#{base_key}_comment_']", visible: :all)
      textarea.set(value)
    end

    def fill_comment_in_context(base_key, base_label, value)
      containers = ["form-grid", "pass-fail-comment", "number-pass-fail-comment"]
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

    def verify_saved_values(inspection, assessment_type, sample_data)
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
