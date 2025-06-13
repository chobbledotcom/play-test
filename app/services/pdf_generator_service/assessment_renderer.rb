class PdfGeneratorService
  class AssessmentRenderer
    include Configuration

    attr_accessor :current_assessment_blocks, :current_assessment_fields

    def initialize
      @current_assessment_blocks = []
      @current_assessment_fields = nil
      @current_assessment_type = nil
      @current_assessment = nil
    end

    private

    # Universal field renderer - handles all field types
    def add(*fields, unit: nil, pass: nil)
      # Build label from i18n
      label = field_label(fields.first)
      parts = ["#{label}:"]

      # Add field values
      fields.each_with_index do |field, i|
        value = @current_assessment.send(field)

        parts << if field.to_s.end_with?("_pass")
          pass_fail(value)
        else
          ((unit && i == 0) ? "#{value}#{unit}" : value.to_s)
        end
      end

      # Add pass/fail if specified
      if pass
        pass_value = @current_assessment.send(pass)
        parts << "-" << pass_fail(pass_value)
      end

      # Add comment if exists
      comment_field = "#{(pass || fields.first).to_s.sub(/_pass$/, "")}_comment"
      if @current_assessment.respond_to?(comment_field)
        comment = @current_assessment.send(comment_field)
        parts << "- #{comment}" if comment.present?
      end

      @current_assessment_fields << parts.join(" ")
    end

    # Get field label from forms namespace
    def field_label(field_name)
      I18n.t("forms.#{@current_assessment_type}.fields.#{field_name}")
    end

    # Format pass/fail values consistently
    def pass_fail(value)
      value ? I18n.t("shared.pass") : I18n.t("shared.fail")
    end

    public

    # Assessment section generators
    def generate_user_height_section(pdf, inspection)
      generate_assessment_section(pdf, "tallest_user_height", inspection.user_height_assessment) do
        # Standard measurement fields
        add :containing_wall_height, unit: "m"
        add :platform_height, unit: "m"
        add :tallest_user_height, unit: "m"
        add :play_area_length, unit: "m"
        add :play_area_width, unit: "m"
        add :permanent_roof if @current_assessment.permanent_roof.present?
        add :negative_adjustment, unit: "m²" if @current_assessment.negative_adjustment.present?

        # User Capacities
        @current_assessment_fields << "#{I18n.t("forms.tallest_user_height.sections.user_capacity")}:"
        %w[1000 1200 1500 1800].each do |height|
          field_name = "users_at_#{height}mm"
          value = @current_assessment.send(field_name) || "N/A"
          @current_assessment_fields << "• #{field_label(field_name)}: #{value}"
        end
      end
    end

    def generate_slide_section(pdf, inspection)
      generate_assessment_section(pdf, "slide", inspection.slide_assessment) do
        # Height measurements
        add :slide_platform_height, unit: "m"
        add :slide_wall_height, unit: "m"
        add :slide_first_metre_height, unit: "m"
        add :slide_beyond_first_metre_height, unit: "m"

        add :slide_permanent_roof if @current_assessment.slide_permanent_roof.present?

        # Pass/fail checks
        add :clamber_netting_pass
        add :slip_sheet_pass

        # Measurement with pass/fail
        add :runout, unit: "m", pass: :runout_pass
      end
    end

    def generate_structure_section(pdf, inspection)
      generate_assessment_section(pdf, "structure", inspection.structure_assessment) do
        # Pass/fail checks
        %i[seam_integrity_pass lock_stitch_pass air_loss_pass straight_walls_pass
          sharp_edges_pass unit_stable_pass evacuation_time_pass].each { |field| add field }

        # Measurements with pass/fail
        add :stitch_length, unit: "mm", pass: :stitch_length_pass
        add :blower_tube_length, unit: "m", pass: :blower_tube_length_pass
        add :unit_pressure_value, unit: "Pa", pass: :unit_pressure_pass
      end
    end

    def generate_anchorage_section(pdf, inspection)
      generate_assessment_section(pdf, "anchorage", inspection.anchorage_assessment) do
        # Anchor counts with combined label
        low = @current_assessment.num_low_anchors || "N/A"
        high = @current_assessment.num_high_anchors || "N/A"
        text = "#{field_label(:num_anchors_pass)}: Low: #{low}, High: #{high}"
        pass_value = @current_assessment.num_anchors_pass
        text += " - #{pass_fail(pass_value)}" unless pass_value.nil?
        @current_assessment_fields << text

        # Pass/fail checks
        %i[anchor_type_pass pull_strength_pass anchor_degree_pass
          anchor_accessories_pass].each { |field| add field }
      end
    end

    def generate_enclosed_section(pdf, inspection)
      generate_assessment_section(pdf, "enclosed", inspection.enclosed_assessment) do
        # Exit number with pass/fail
        add :exit_number, pass: :exit_number_pass

        # Pass/fail checks
        add :exit_sign_always_visible_pass
      end
    end

    def generate_materials_section(pdf, inspection)
      generate_assessment_section(pdf, "materials", inspection.materials_assessment) do
        # Pass/fail checks
        %i[fabric_strength_pass fire_retardant_pass thread_pass].each { |field| add field }

        # Rope size with pass/fail
        add :ropes, unit: "mm", pass: :ropes_pass
      end
    end

    def generate_fan_section(pdf, inspection)
      generate_assessment_section(pdf, "fan", inspection.fan_assessment) do
        # Pass/fail checks
        %i[blower_flap_pass blower_finger_pass pat_pass blower_visual_pass].each { |field| add field }

        # Optional text fields
        add :blower_serial if @current_assessment.blower_serial.present?
        add :fan_size_type if @current_assessment.fan_size_type.present?
      end
    end

    def generate_risk_assessment_section(pdf, inspection)
      # This section doesn't exist in the current model
      # Placeholder for future implementation
    end

    # Generic helper methods for DRY code
    def generate_assessment_section(pdf, assessment_type, assessment)
      title = I18n.t("forms.#{assessment_type}.header")

      if assessment&.complete?
        # Set up instance variables for the block
        @current_assessment_type = assessment_type
        @current_assessment = assessment
        @current_assessment_fields = []

        # Execute the block
        yield

        # Create a complete assessment block with title and fields
        @current_assessment_blocks ||= []
        @current_assessment_blocks << {
          title: title,
          fields: @current_assessment_fields
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
