class PdfGeneratorService
  class AssessmentRenderer
    include Configuration

    attr_accessor :current_assessment_blocks, :current_assessment_fields

    def initialize
      @current_assessment_blocks = []
      @current_assessment_fields = nil
    end

    # Assessment section generators
    def generate_user_height_section(pdf, inspection)
      generate_assessment_section(pdf, "user_height", inspection.user_height_assessment) do |assessment, type, fields|
        # Standard measurement fields
        measurement_fields = [
          [:containing_wall_height, "m"],
          [:platform_height, "m"],
          [:tallest_user_height, "m"],
          [:play_area_length, "m"],
          [:play_area_width, "m"]
        ]

        measurement_fields.each do |field, unit|
          FieldFormatter.add_field_with_comment(fields, assessment, field, unit, type)
        end

        # Permanent Roof
        if !assessment.permanent_roof.nil?
          FieldFormatter.add_boolean_field_with_comment(fields, assessment, :permanent_roof, type)
        end

        # Negative Adjustment
        if assessment.negative_adjustment.present?
          FieldFormatter.add_field_with_comment(fields, assessment, :negative_adjustment, "m²", type)
        end

        # User Capacities - add as a section header
        fields << "#{I18n.t("inspections.assessments.user_height.sections.user_capacities")}:"

        user_capacity_heights = [1000, 1200, 1500, 1800]
        user_capacity_heights.each do |height|
          field_name = "users_at_#{height}mm"
          value = assessment.send(field_name) || I18n.t("pdf.inspection.fields.na")
          capacity_text = "• #{I18n.t("inspections.assessments.user_height.fields.#{field_name}")}: #{value}"
          fields << capacity_text
        end
      end
    end

    def generate_slide_section(pdf, inspection)
      generate_assessment_section(pdf, "slide", inspection.slide_assessment) do |assessment, type, fields|
        # Height measurement fields
        height_fields = [
          [:slide_platform_height, "m"],
          [:slide_wall_height, "m"],
          [:slide_first_metre_height, "m"],
          [:slide_beyond_first_metre_height, "m"]
        ]

        height_fields.each do |field, unit|
          FieldFormatter.add_field_with_comment(fields, assessment, field, unit, type)
        end

        # Permanent Roof
        if !assessment.slide_permanent_roof.nil?
          FieldFormatter.add_boolean_field_with_comment(fields, assessment, :slide_permanent_roof, type)
        end

        # Pass/fail fields
        pass_fail_fields = [:clamber_netting_pass, :slip_sheet_pass]
        pass_fail_fields.each do |field|
          FieldFormatter.add_pass_fail_field_with_comment(fields, assessment, field, type)
        end

        # Runout (special case with measurement and pass/fail)
        FieldFormatter.add_measurement_pass_fail_field(fields, assessment, :runout_value, "m", :runout_pass, type)
      end
    end

    def generate_structure_section(pdf, inspection)
      generate_assessment_section(pdf, "structure", inspection.structure_assessment) do |assessment, type, fields|
        # Simple pass/fail fields
        pass_fail_fields = [
          :seam_integrity_pass,
          :lock_stitch_pass,
          :air_loss_pass,
          :straight_walls_pass,
          :sharp_edges_pass,
          :unit_stable_pass,
          :evacuation_time_pass
        ]

        pass_fail_fields.each do |field|
          FieldFormatter.add_pass_fail_field_with_comment(fields, assessment, field, type)
        end

        # Measurement fields with pass/fail
        measurement_fields = [
          [:stitch_length, "mm", :stitch_length_pass],
          [:blower_tube_length, "m", :blower_tube_length_pass],
          [:unit_pressure_value, "Pa", :unit_pressure_pass]
        ]

        measurement_fields.each do |value_field, unit, pass_field|
          FieldFormatter.add_measurement_pass_fail_field(fields, assessment, value_field, unit, pass_field, type)
        end
      end
    end

    def generate_anchorage_section(pdf, inspection)
      generate_assessment_section(pdf, "anchorage", inspection.anchorage_assessment) do |assessment, type, fields|
        # Number of anchors with special formatting
        label = I18n.t("inspections.assessments.anchorage.fields.num_anchors_pass")
        anchor_text = "#{label}: #{I18n.t("inspections.assessments.anchorage.fields.num_low_anchors")}: #{assessment.num_low_anchors || I18n.t("pdf.inspection.fields.na")}, #{I18n.t("inspections.assessments.anchorage.fields.num_high_anchors")}: #{assessment.num_high_anchors || I18n.t("pdf.inspection.fields.na")}"
        FieldFormatter.add_text_pass_fail_field(fields, anchor_text, assessment, :num_anchors_pass)

        # Pass/fail fields
        pass_fail_fields = [
          :anchor_type_pass,
          :pull_strength_pass,
          :anchor_degree_pass,
          :anchor_accessories_pass
        ]

        pass_fail_fields.each do |field|
          FieldFormatter.add_pass_fail_field_with_comment(fields, assessment, field, type)
        end
      end
    end

    def generate_enclosed_section(pdf, inspection)
      generate_assessment_section(pdf, "enclosed", inspection.enclosed_assessment) do |assessment, type, fields|
        # Exit number with pass/fail
        label = I18n.t("inspections.assessments.enclosed.fields.exit_number")
        exit_text = "#{label}: #{assessment.exit_number || I18n.t("pdf.inspection.fields.na")}"
        FieldFormatter.add_text_pass_fail_field(fields, exit_text, assessment, :exit_number_pass)

        FieldFormatter.add_pass_fail_field_with_comment(fields, assessment, :exit_visible_pass, type)
      end
    end

    def generate_materials_section(pdf, inspection)
      generate_assessment_section(pdf, "materials", inspection.materials_assessment) do |assessment, type, fields|
        # Pass/fail fields
        pass_fail_fields = [:fabric_pass, :fire_retardant_pass, :thread_pass]
        pass_fail_fields.each do |field|
          FieldFormatter.add_pass_fail_field_with_comment(fields, assessment, field, type)
        end

        # Rope size with measurement
        FieldFormatter.add_measurement_pass_fail_field(fields, assessment, :rope_size, "mm", :rope_size_pass, type)
      end
    end

    def generate_fan_section(pdf, inspection)
      generate_assessment_section(pdf, "fan", inspection.fan_assessment) do |assessment, type, fields|
        # Pass/fail fields
        pass_fail_fields = [
          :blower_flap_pass,
          :blower_finger_pass,
          :pat_pass,
          :blower_visual_pass
        ]

        pass_fail_fields.each do |field|
          FieldFormatter.add_pass_fail_field_with_comment(fields, assessment, field, type)
        end

        # Optional text fields
        optional_fields = [
          [:blower_serial, nil],
          [:fan_size_comment, nil]
        ]

        optional_fields.each do |field, _|
          if assessment.send(field).present?
            label = I18n.t("inspections.assessments.fan.fields.#{field}")
            value = assessment.send(field)
            field_text = "#{label}: #{value}"
            fields << field_text
          end
        end
      end
    end

    def generate_risk_assessment_section(pdf, inspection)
      # This section doesn't exist in the current model
      # Placeholder for future implementation
    end

    # Generic helper methods for DRY code
    def generate_assessment_section(pdf, assessment_type, assessment)
      title = I18n.t("inspections.assessments.#{assessment_type}.title")

      if assessment
        # Collect all field data first
        fields = []
        yield(assessment, assessment_type, fields)

        # Create a complete assessment block with title and fields
        @current_assessment_blocks ||= []
        @current_assessment_blocks << {
          title: title,
          fields: fields
        }
      else
        # For assessments with no data, still add to blocks
        @current_assessment_blocks ||= []
        @current_assessment_blocks << {
          title: title,
          fields: [I18n.t("pdf.inspection.no_assessment_data", assessment_type: title)]
        }
      end
    end

    # New method to render all assessment blocks in newspaper-style columns
    def render_all_assessments_in_columns(pdf)
      return if @current_assessment_blocks.nil? || @current_assessment_blocks.empty?

      # Add section header
      pdf.text I18n.t("pdf.inspection.assessments_section"), size: 12, style: :bold
      pdf.stroke_horizontal_rule
      pdf.move_down 15

      # Use Prawn's built-in column layout
      pdf.column_box([0, pdf.cursor], columns: 3, width: pdf.bounds.width, spacer: 10) do
        @current_assessment_blocks.each do |block|
          render_assessment_block(pdf, block)
        end
      end

      # Clean up
      @current_assessment_blocks = []
      pdf.move_down 20
    end

    # Helper method to render a single assessment block
    def render_assessment_block(pdf, block)
      # Render title
      pdf.text block[:title], size: 10, style: :bold
      pdf.move_down 3

      # Render fields
      block[:fields].each do |field_text|
        pdf.text field_text, size: 7
      end

      pdf.move_down 8  # Space between assessment blocks
    end

    # Class methods that delegate to instance methods
    def self.generate_user_height_section(pdf, inspection)
      renderer = new
      renderer.generate_user_height_section(pdf, inspection)
      renderer
    end

    def self.generate_slide_section(pdf, inspection)
      renderer = new
      renderer.generate_slide_section(pdf, inspection)
      renderer
    end

    def self.generate_structure_section(pdf, inspection)
      renderer = new
      renderer.generate_structure_section(pdf, inspection)
      renderer
    end

    def self.generate_anchorage_section(pdf, inspection)
      renderer = new
      renderer.generate_anchorage_section(pdf, inspection)
      renderer
    end

    def self.generate_enclosed_section(pdf, inspection)
      renderer = new
      renderer.generate_enclosed_section(pdf, inspection)
      renderer
    end

    def self.generate_materials_section(pdf, inspection)
      renderer = new
      renderer.generate_materials_section(pdf, inspection)
      renderer
    end

    def self.generate_fan_section(pdf, inspection)
      renderer = new
      renderer.generate_fan_section(pdf, inspection)
      renderer
    end

    def self.generate_risk_assessment_section(pdf, inspection)
      renderer = new
      renderer.generate_risk_assessment_section(pdf, inspection)
      renderer
    end
  end
end
