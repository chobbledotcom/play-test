# Comprehensive PDF Generator Service
# Implements the full PDF layout as described in PDF_GENERATION.md
class ComprehensivePdfGeneratorService
  def self.generate_inspection_report(inspection)
    require "prawn/table"

    Prawn::Document.new(page_size: "A4", margin: 15) do |pdf|
      setup_pdf_fonts(pdf)

      # Store starting Y position for two-column layout
      start_y = pdf.cursor

      # Left column content
      pdf.bounding_box([0, start_y], width: 280, height: pdf.cursor) do
        generate_header(pdf, inspection)
        generate_unit_details(pdf, inspection)
        generate_user_height_section(pdf, inspection)
        generate_slide_section(pdf, inspection) if inspection.unit&.has_slide?
        generate_structure_left_column(pdf, inspection)
      end

      # Right column content - start at same Y position
      pdf.bounding_box([297.5, start_y], width: 280, height: pdf.cursor) do
        # Add images at top of right column
        add_images(pdf, inspection)
        pdf.move_down 120 # Space for images

        generate_structure_right_column(pdf, inspection)
        generate_anchorage_section(pdf, inspection)
        generate_enclosed_section(pdf, inspection) if inspection.unit&.is_totally_enclosed?
        generate_materials_section(pdf, inspection)
        generate_fan_section(pdf, inspection)
      end

      # Move to bottom of columns for remaining sections
      pdf.move_cursor_to [50, 280].min

      # Full-width sections at bottom
      generate_risk_assessment(pdf, inspection)
      generate_testimony(pdf, inspection)
      generate_final_result(pdf, inspection)
      generate_footer(pdf)
    end
  end

  private

  def self.setup_pdf_fonts(pdf)
    font_path = Rails.root.join("app", "assets", "fonts")
    pdf.font_families.update(
      "NotoSans" => {
        normal: "#{font_path}/NotoSans-Regular.ttf",
        bold: "#{font_path}/NotoSans-Bold.ttf"
      }
    )
    pdf.font "NotoSans"
  end

  def self.generate_header(pdf, inspection)
    # RPII Inspector Issued Report
    pdf.font("NotoSans", size: 14, style: :bold) do
      pdf.text "RPII Inspector Issued Report", color: "CC0000"
    end

    # Issued by company
    if inspection.inspection_company_name.present?
      pdf.font("NotoSans", size: 12, style: :bold) do
        pdf.text "Issued by: #{inspection.inspection_company_name}"
      end
    end

    # Issue date
    pdf.font("NotoSans", size: 14, style: :bold) do
      pdf.text "Issued #{inspection.inspection_date&.strftime("%d/%m/%Y") || "N/A"}", color: "CC0000"
    end

    # RPII Registration Number
    if inspection.rpii_registration_number.present?
      pdf.font("NotoSans", size: 14, style: :bold) do
        pdf.text "RPII Reg Number: #{inspection.rpii_registration_number}", color: "CC0000"
      end
    end

    # Place of Inspection
    if inspection.place_inspected.present?
      pdf.font("NotoSans", size: 8, style: :bold) do
        pdf.text "Place of Inspection: #{truncate(inspection.place_inspected, 60)}", color: "CC0000"
      end
    end

    # Unique Report Number
    pdf.font("NotoSans", size: 12, style: :bold) do
      pdf.text "Unique Report Number: #{inspection.id}", color: "CC0000"
    end

    pdf.move_down 15
  end

  def self.generate_unit_details(pdf, inspection)
    pdf.font("NotoSans", size: 12, style: :bold) do
      pdf.text "Unit Details"
    end

    unit = inspection.unit

    pdf.font("NotoSans", size: 8) do
      if unit
        pdf.text "Description: #{truncate(unit.name || unit.description || "N/A", 66)}"
        pdf.text "Manufacturer: #{unit.manufacturer || "N/A"}"

        # Dimensions
        if unit.width.present? || unit.length.present? || unit.height.present?
          dims = []
          dims << "Width: #{unit.width}" if unit.width.present?
          dims << "Length: #{unit.length}" if unit.length.present?
          dims << "Height: #{unit.height}" if unit.height.present?
          pdf.text "Size (m): #{dims.join(" ")}"
        end

        pdf.text "Serial Number / Asset ID: #{unit.serial_number || "N/A"}"
        pdf.text "Owner: #{unit.owner}" if unit.owner.present?
        pdf.text "Type: #{unit.has_slide? ? "Unit with Slide" : "Standard Unit"}"
      else
        pdf.text "No unit associated with this inspection", style: :italic
      end
    end

    pdf.move_down 10
  end

  def self.generate_user_height_section(pdf, inspection)
    pdf.font("NotoSans", size: 12, style: :bold) do
      pdf.text "User Height/Count"
    end

    assessment = inspection.user_height_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        # Wall and platform measurements
        pdf.text "Containing wall height: #{fmt_measurement(assessment.containing_wall_height, "m")} #{truncate(assessment.containing_wall_height_comment, 60)}"
        pdf.text "Platform height: #{fmt_measurement(assessment.platform_height, "m")} #{truncate(assessment.platform_height_comment, 60)}"

        # Permanent roof
        if !assessment.permanent_roof.nil?
          pdf.text "Permanent roof: #{assessment.permanent_roof ? "Yes" : "No"} #{truncate(assessment.permanent_roof_comment, 60)}"
        end

        # User height
        pdf.text "User height: #{fmt_measurement(assessment.user_height, "m")} #{truncate(assessment.user_height_comment, 60)}"

        # Play area
        pdf.text "Play area length: #{fmt_measurement(assessment.play_area_length, "m")} #{truncate(assessment.play_area_length_comment, 60)}"
        pdf.text "Play area width: #{fmt_measurement(assessment.play_area_width, "m")} #{truncate(assessment.play_area_width_comment, 60)}"

        # Negative adjustment
        if assessment.negative_adjustment.present?
          pdf.text "Negative adjustment: #{fmt_measurement(assessment.negative_adjustment, "m²")} #{truncate(assessment.negative_adjustment_comment, 60)}"
        end

        # User capacities
        pdf.move_down 5
        pdf.font("NotoSans", size: 8, style: :bold) do
          pdf.text "User capacities:"
        end
        pdf.text "• 1.0m users: #{assessment.users_at_1000mm || "N/A"}"
        pdf.text "• 1.2m users: #{assessment.users_at_1200mm || "N/A"}"
        pdf.text "• 1.5m users: #{assessment.users_at_1500mm || "N/A"}"
        pdf.text "• 1.8m users: #{assessment.users_at_1800mm || "N/A"}"
      else
        pdf.text "No user height assessment data", style: :italic
      end
    end

    pdf.move_down 10
  end

  def self.generate_slide_section(pdf, inspection)
    pdf.font("NotoSans", size: 12, style: :bold) do
      pdf.text "Slide"
    end

    assessment = inspection.slide_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        pdf.text "Slide platform height: #{fmt_measurement(assessment.slide_platform_height, "m")} #{truncate(assessment.slide_platform_height_comment, 60)}"
        pdf.text "Slide wall height: #{fmt_measurement(assessment.slide_wall_height, "m")} #{truncate(assessment.slide_wall_height_comment, 60)}"
        pdf.text "Slide 1st metre wall height: #{fmt_measurement(assessment.slide_first_metre_height, "m")} #{truncate(assessment.slide_first_metre_height_comment, 60)}"
        pdf.text "Slide wall height after 1st metre: #{fmt_measurement(assessment.slide_beyond_first_metre_height, "m")} #{truncate(assessment.slide_beyond_first_metre_height_comment, 60)}"

        if !assessment.slide_permanent_roof.nil?
          pdf.text "Slide permanent roof: #{assessment.slide_permanent_roof ? "Yes" : "No"} #{truncate(assessment.slide_permanent_roof_comment, 60)}"
        end

        pdf.text "Clamber netting suitable: #{pass_fail(assessment.clamber_netting_pass)} #{truncate(assessment.clamber_netting_comment, 60)}"
        pdf.text "Run-out: #{fmt_measurement(assessment.runout_value, "m")} - #{pass_fail(assessment.runout_pass)} #{truncate(assessment.runout_comment, 60)}"
        pdf.text "Slip sheet where applicable: #{pass_fail(assessment.slip_sheet_pass)} #{truncate(assessment.slip_sheet_comment, 60)}"
      else
        pdf.text "No slide assessment data", style: :italic
      end
    end

    pdf.move_down 10
  end

  def self.generate_structure_left_column(pdf, inspection)
    pdf.font("NotoSans", size: 12, style: :bold) do
      pdf.text "Structure"
    end

    assessment = inspection.structure_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        pdf.text "Seam integrity: #{pass_fail(assessment.seam_integrity_pass)} #{truncate(assessment.seam_integrity_comment, 60)}"
        pdf.text "Lock stitch: #{pass_fail(assessment.lock_stitch_pass)} #{truncate(assessment.lock_stitch_comment, 60)}"
        pdf.text "Stitch length: #{fmt_measurement(assessment.stitch_length, "mm")} - #{pass_fail(assessment.stitch_length_pass)} #{truncate(assessment.stitch_length_comment, 60)}"
        pdf.text "Air loss: #{pass_fail(assessment.air_loss_pass)} #{truncate(assessment.air_loss_comment, 60)}"
        pdf.text "Straight walls: #{pass_fail(assessment.straight_walls_pass)} #{truncate(assessment.straight_walls_comment, 60)}"
        pdf.text "Sharp edges: #{pass_fail(assessment.sharp_edges_pass)} #{truncate(assessment.sharp_edges_comment, 60)}"
        pdf.text "Blower tube length: #{fmt_measurement(assessment.blower_tube_length, "m")} - #{pass_fail(assessment.blower_tube_length_pass)} #{truncate(assessment.blower_tube_length_comment, 60)}"
        pdf.text "Unit stable: #{pass_fail(assessment.unit_stable_pass)} #{truncate(assessment.unit_stable_comment, 60)}"
        pdf.text "Evacuation time <30s: #{pass_fail(assessment.evacuation_time_pass)} #{truncate(assessment.evacuation_time_comment, 60)}"
      else
        pdf.text "No structure assessment data", style: :italic
      end
    end
  end

  def self.generate_structure_right_column(pdf, inspection)
    pdf.font("NotoSans", size: 10, style: :bold) do
      pdf.text "Structure (continued)"
    end

    assessment = inspection.structure_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        pdf.text "Step size: #{fmt_measurement(assessment.step_size_value, "mm")} - #{pass_fail(assessment.step_size_pass)} #{truncate(assessment.step_size_comment, 40)}"
        pdf.text "Fall-off height: #{fmt_measurement(assessment.fall_off_height_value, "m")} - #{pass_fail(assessment.fall_off_height_pass)} #{truncate(assessment.fall_off_height_comment, 40)}"
        pdf.text "Unit pressure: #{fmt_measurement(assessment.unit_pressure_value, "kPa")} - #{pass_fail(assessment.unit_pressure_pass)} #{truncate(assessment.unit_pressure_comment, 40)}"

        # Trough measurements
        if assessment.trough_depth_value.present? || assessment.trough_width_value.present?
          trough = []
          trough << "D: #{assessment.trough_depth_value}mm" if assessment.trough_depth_value.present?
          trough << "W: #{assessment.trough_width_value}mm" if assessment.trough_width_value.present?
          pdf.text "Trough: #{trough.join(", ")} - #{pass_fail(assessment.trough_pass)} #{truncate(assessment.trough_comment, 40)}"
        end

        # Additional checks
        pdf.text "Tubes present: #{pass_fail(assessment.tubes_present_pass)} #{truncate(assessment.tubes_present_comment, 40)}"
        pdf.text "Netting: #{pass_fail(assessment.netting_pass)} #{truncate(assessment.netting_comment, 40)}"
        pdf.text "Ventilation: #{pass_fail(assessment.ventilation_pass)} #{truncate(assessment.ventilation_comment, 40)}"
        pdf.text "Step heights: #{pass_fail(assessment.step_heights_pass)} #{truncate(assessment.step_heights_comment, 40)}"
        pdf.text "Opening dimension: #{pass_fail(assessment.opening_dimension_pass)} #{truncate(assessment.opening_dimension_comment, 40)}"
        pdf.text "Entrances: #{pass_fail(assessment.entrances_pass)} #{truncate(assessment.entrances_comment, 40)}"
        pdf.text "Fabric integrity: #{pass_fail(assessment.fabric_integrity_pass)} #{truncate(assessment.fabric_integrity_comment, 40)}"
        pdf.text "Entrapment: #{pass_fail(assessment.entrapment_pass)} #{truncate(assessment.entrapment_comment, 40)}"
        pdf.text "Markings: #{pass_fail(assessment.markings_pass)} #{truncate(assessment.markings_comment, 40)}"
        pdf.text "Grounding: #{pass_fail(assessment.grounding_pass)} #{truncate(assessment.grounding_comment, 40)}"
      end
    end

    pdf.move_down 10
  end

  def self.generate_anchorage_section(pdf, inspection)
    pdf.font("NotoSans", size: 10, style: :bold) do
      pdf.text "Anchorage System"
    end

    assessment = inspection.anchorage_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        pdf.text "Low anchors: #{assessment.num_low_anchors || "N/A"}"
        pdf.text "High anchors: #{assessment.num_high_anchors || "N/A"}"
        pdf.text "Total anchors: #{assessment.total_anchors}"

        if inspection.unit&.area.present?
          required = assessment.required_anchors
          pdf.text "Required anchors: #{required}"
          pdf.text "Compliance: #{assessment.meets_anchor_requirements? ? "Pass" : "Fail"}"
        end

        pdf.text "Number suitable: #{pass_fail(assessment.num_anchors_pass)} #{truncate(assessment.num_anchors_comment, 40)}"
        pdf.text "Type suitable: #{pass_fail(assessment.anchor_type_pass)} #{truncate(assessment.anchor_type_comment, 40)}"
        pdf.text "Accessories: #{pass_fail(assessment.anchor_accessories_pass)} #{truncate(assessment.anchor_accessories_comment, 40)}"
        pdf.text "Angle 30-45°: #{pass_fail(assessment.anchor_degree_pass)} #{truncate(assessment.anchor_degree_comment, 40)}"
        pdf.text "Pull strength: #{pass_fail(assessment.pull_strength_pass)} #{truncate(assessment.pull_strength_comment, 40)}"
      else
        pdf.text "No anchorage assessment data", style: :italic
      end
    end

    pdf.move_down 10
  end

  def self.generate_enclosed_section(pdf, inspection)
    pdf.font("NotoSans", size: 10, style: :bold) do
      pdf.text "Totally Enclosed Equipment"
    end

    assessment = inspection.enclosed_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        pdf.text "Exit number: #{assessment.exit_number || "N/A"} - #{pass_fail(assessment.exit_number_pass)} #{truncate(assessment.exit_number_comment, 40)}"
        pdf.text "Exit visible: #{pass_fail(assessment.exit_visible_pass)} #{truncate(assessment.exit_visible_comment, 40)}"
      else
        pdf.text "No enclosed assessment data", style: :italic
      end
    end

    pdf.move_down 10
  end

  def self.generate_materials_section(pdf, inspection)
    pdf.font("NotoSans", size: 10, style: :bold) do
      pdf.text "Materials"
    end

    assessment = inspection.materials_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        pdf.text "Rope size: #{fmt_measurement(assessment.rope_size, "mm")} - #{pass_fail(assessment.rope_size_pass)} #{truncate(assessment.rope_size_comment, 40)}"
        pdf.text "Clamber: #{pass_fail(assessment.clamber_pass)} #{truncate(assessment.clamber_comment, 40)}"
        pdf.text "Retention netting: #{pass_fail(assessment.retention_netting_pass)} #{truncate(assessment.retention_netting_comment, 40)}"
        pdf.text "Zips: #{pass_fail(assessment.zips_pass)} #{truncate(assessment.zips_comment, 40)}"
        pdf.text "Windows: #{pass_fail(assessment.windows_pass)} #{truncate(assessment.windows_comment, 40)}"
        pdf.text "Artwork: #{pass_fail(assessment.artwork_pass)} #{truncate(assessment.artwork_comment, 40)}"
        pdf.text "Thread: #{pass_fail(assessment.thread_pass)} #{truncate(assessment.thread_comment, 40)}"
        pdf.text "Fabric: #{pass_fail(assessment.fabric_pass)} #{truncate(assessment.fabric_comment, 40)}"
        pdf.text "Fire retardant: #{pass_fail(assessment.fire_retardant_pass)} #{truncate(assessment.fire_retardant_comment, 40)}"

        # Additional material checks if present
        [:marking_pass, :instructions_pass, :inflated_stability_pass, :protrusions_pass, :critical_defects_pass].each do |field|
          if assessment.respond_to?(field) && !assessment.send(field).nil?
            field_name = field.to_s.sub("_pass", "").humanize
            comment_field = field.to_s.sub("_pass", "_comment")
            pdf.text "#{field_name}: #{pass_fail(assessment.send(field))} #{truncate(assessment.send(comment_field), 40)}"
          end
        end
      else
        pdf.text "No materials assessment data", style: :italic
      end
    end

    pdf.move_down 10
  end

  def self.generate_fan_section(pdf, inspection)
    pdf.font("NotoSans", size: 10, style: :bold) do
      pdf.text "Fan/Blower"
    end

    assessment = inspection.fan_assessment

    pdf.font("NotoSans", size: 8) do
      if assessment
        pdf.text "Blower size: #{truncate(assessment.fan_size_comment, 40)}" if assessment.fan_size_comment.present?
        pdf.text "Return flap: #{pass_fail(assessment.blower_flap_pass)} #{truncate(assessment.blower_flap_comment, 40)}"
        pdf.text "Finger probe: #{pass_fail(assessment.blower_finger_pass)} #{truncate(assessment.blower_finger_comment, 40)}"
        pdf.text "PAT: #{pass_fail(assessment.pat_pass)} #{truncate(assessment.pat_comment, 40)}"
        pdf.text "Visual: #{pass_fail(assessment.blower_visual_pass)} #{truncate(assessment.blower_visual_comment, 40)}"
        pdf.text "Serial: #{assessment.blower_serial || "N/A"}"
      else
        pdf.text "No fan/blower assessment data", style: :italic
      end
    end

    pdf.move_down 10
  end

  def self.add_images(pdf, inspection)
    # Unit photo (top right)
    if inspection.unit&.photo&.attached?
      pdf.image inspection.unit.photo, at: [400, pdf.cursor], width: 128, height: 95
    end

    # Inspector company logo (below unit photo)
    if inspection.inspector_company&.logo&.attached?
      pdf.image inspection.inspector_company.logo, at: [400, pdf.cursor - 110], width: 128, height: 95
    end
  end

  def self.generate_risk_assessment(pdf, inspection)
    return unless inspection.general_notes.present?

    # Lavender background box
    pdf.fill_color "FFF0F5"
    pdf.fill_rectangle [pdf.bounds.left, pdf.cursor], pdf.bounds.width, 25
    pdf.fill_color "000000"

    pdf.bounding_box([pdf.bounds.left + 5, pdf.cursor - 5], width: pdf.bounds.width - 10, height: 20) do
      pdf.font("NotoSans", size: 6) do
        pdf.text "Risk Assessment: #{truncate(inspection.general_notes, 200)}"
      end
    end

    pdf.move_down 25
  end

  def self.generate_testimony(pdf, inspection)
    return unless inspection.comments.present?

    # Lavender background box
    pdf.fill_color "FFF0F5"
    pdf.fill_rectangle [pdf.bounds.left, pdf.cursor], pdf.bounds.width, 15
    pdf.fill_color "000000"

    pdf.bounding_box([pdf.bounds.left + 5, pdf.cursor - 5], width: pdf.bounds.width - 10, height: 10) do
      pdf.font("NotoSans", size: 6) do
        pdf.text "Testimony: #{truncate(inspection.comments, 200)}"
      end
    end

    pdf.move_down 15
  end

  def self.generate_final_result(pdf, inspection)
    result_text = inspection.passed ? "Passed Inspection" : "Failed Inspection"
    result_color = inspection.passed ? "009900" : "CC0000"

    pdf.font("NotoSans", size: 14, style: :bold) do
      pdf.text result_text, color: result_color, align: :center
    end

    pdf.move_down 10
  end

  def self.generate_footer(pdf)
    # Seashell background box
    pdf.fill_color "FFF5EE"
    pdf.fill_rectangle [pdf.bounds.width / 2, pdf.cursor], pdf.bounds.width / 2, 10
    pdf.fill_color "000000"

    pdf.bounding_box([pdf.bounds.width / 2 + 5, pdf.cursor - 2], width: pdf.bounds.width / 2 - 10, height: 8) do
      pdf.font("NotoSans", size: 8, style: :bold) do
        pdf.text "The software used to generate this report was made by Spencer Elliott.", align: :right
      end
    end
  end

  # Helper methods
  def self.truncate(text, max_length)
    return "" if text.nil?
    (text.length > max_length) ? "#{text[0...max_length]}..." : text
  end

  def self.pass_fail(value)
    case value
    when true then "Pass"
    when false then "Fail"
    else "N/A"
    end
  end

  def self.fmt_measurement(value, unit = "")
    return "N/A" if value.nil?
    "#{value}#{unit}"
  end
end
