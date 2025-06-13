RSpec.shared_examples "assessment form save" do |assessment_type, sample_data|
  describe "#{assessment_type} assessment form" do
    let(:user) { create(:user) }
    let(:unit) { create(:unit, user: user) }
    let(:inspection) do
      # Create inspection with appropriate traits for assessment type
      case assessment_type
      when :enclosed
        create(:inspection, :totally_enclosed, user: user, unit: unit)
      when :slide
        create(:inspection, user: user, unit: unit, has_slide: true)
      else
        create(:inspection, user: user, unit: unit)
      end
    end

    before { sign_in(user) }

    it "saves all #{assessment_type} assessment fields correctly" do
      # Visit the assessment tab
      tab_name = assessment_type == :user_height ? "user_height" : assessment_type.to_s
      visit edit_inspection_path(inspection, tab: tab_name)

      # Get i18n base for this assessment
      i18n_key = assessment_type == :user_height ? "tallest_user_height" : assessment_type.to_s
      i18n_base = "forms.#{i18n_key}"
      
      # Get all field translations
      fields = I18n.t("#{i18n_base}.fields")
      
      # Debug: save page to see what's on it
      save_and_open_page if ENV['DEBUG'] || ENV['SAVE_PAGE']
      
      # Debug: print all radio button IDs on the page
      if ENV['DEBUG']
        all('input[type="radio"]').each do |radio|
          puts "Radio ID: #{radio[:id]}, Name: #{radio[:name]}, Value: #{radio[:value]}"
        end
      end
      
      # Fill in each field based on sample data
      sample_data.each do |field_key, value|
        # Skip pass/fail field labels - they're handled by radio buttons
        if field_key.to_s.end_with?('_pass')
          # For pass/fail fields, find the radio button by ID
          # The ID format is: field_name_true/false
          radio_id = "#{field_key}_#{value}"
          choose radio_id
        else
          # Raise error if field is not in i18n - we must have all fields defined
          unless fields.key?(field_key)
            raise "Field #{field_key} is in sample data but not in i18n at #{i18n_base}.fields.#{field_key}"
          end
          
          field_label = fields[field_key]
          puts "Filling #{field_key} (#{field_label}) with #{value}" if ENV['DEBUG']
          
          case value
          when true, false
            # For boolean fields that aren't _pass fields
            radio_id = "#{field_key}_#{value}"
            choose radio_id
          when Numeric
            # For number fields
            fill_in field_label, with: value.to_s
          when String
            # For text fields, handle comment fields specially
            if field_key.to_s.end_with?('_comment')
              # Find the comment field near the related field
              base_field = field_key.to_s.chomp('_comment')
              # First, ensure the comment field is visible by checking its checkbox if present
              # The checkbox ID is: #{field}_has_comment_#{model.object_id}
              comment_checkbox = find("input[type='checkbox'][id*='#{base_field}_has_comment_']")
              comment_checkbox.check if comment_checkbox && !comment_checkbox.checked?
              # Then fill in the comment
              fill_in(/#{field_key}/i, with: value)
            else
              fill_in field_label, with: value
            end
          end
        end
      end
      
      # Submit the form
      click_button I18n.t("#{i18n_base}.submit")
      
      # Verify success message
      expect(page).to have_content(I18n.t("inspections.messages.updated"))
      
      # Reload and get the assessment
      inspection.reload
      assessment = inspection.send("#{assessment_type}_assessment")
      
      # Verify each field was saved correctly
      sample_data.each do |field_key, expected_value|
        actual_value = assessment.send(field_key)
        
        case expected_value
        when Float
          expect(actual_value).to eq(expected_value), 
            "Expected #{field_key} to be #{expected_value} but got #{actual_value}"
        when Integer
          expect(actual_value).to eq(expected_value),
            "Expected #{field_key} to be #{expected_value} but got #{actual_value}"
        else
          expect(actual_value).to eq(expected_value),
            "Expected #{field_key} to be #{expected_value.inspect} but got #{actual_value.inspect}"
        end
      end
    end
  end
end