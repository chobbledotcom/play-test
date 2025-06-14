class SeedDataService
  CASTLE_IMAGE_COUNT = 5
  UNIT_COUNT = 20
  INSPECTION_COUNT = 5
  INSPECTION_INTERVAL_DAYS = 364
  INSPECTION_OFFSET_RANGE = 0..365
  INSPECTION_DURATION_RANGE = 1..4
  HIGH_PASS_RATE = 0.95
  NORMAL_PASS_RATE = 0.85

  # Stefan-variant owner names as per existing seeds
  STEFAN_OWNER_NAMES = [
    "Stefan's Bouncers",
    "Steph's Castles",
    "Steve's Inflatables",
    "Stefano's Party Hire",
    "Stef's Fun Factory",
    "Stefan Family Inflatables",
    "Stephan's Adventure Co",
    "Estephan Events",
    "Steff's Soft Play"
  ].freeze

  # Load seed helpers
  require Rails.root.join("lib", "test_data_helpers")

  class << self
    def add_seeds_for_user(user)
      raise "User already has seed data" if user.has_seed_data?

      ActiveRecord::Base.transaction do
        Rails.logger.info I18n.t("seed_data.logging.starting_creation", user_id: user.id)
        ensure_castle_blobs_exist
        Rails.logger.info I18n.t("seed_data.logging.castle_images_found", count: @castle_images.size)
        create_seed_units_for_user(user)
        Rails.logger.info I18n.t("seed_data.logging.creation_completed")
      end
      true
    end

    def delete_seeds_for_user(user)
      ActiveRecord::Base.transaction do
        # Delete inspections first (due to foreign key constraints)
        user.inspections.seed_data.destroy_all
        # Then delete units
        user.units.seed_data.destroy_all
      end
      true
    end

    private

    def ensure_castle_blobs_exist
      @castle_images = []

      (1..CASTLE_IMAGE_COUNT).each do |i|
        filename = "castle-#{i}.jpg"
        filepath = Rails.root.join("app/assets/castles", filename)

        next unless File.exist?(filepath)

        # Read and cache the file content in memory
        @castle_images << {
          filename: filename,
          content: File.read(filepath, mode: "rb") # Read in binary mode for images
        }
      end

      # If no castle images found, don't fail - just log
      Rails.logger.warn I18n.t("seed_data.logging.no_castle_images") if @castle_images.empty?
    end

    def create_seed_units_for_user(user)
      # Mix of unit types similar to existing seeds
      unit_configs = [
        {name: "Medieval Castle Bouncer", manufacturer: "Airquee Manufacturing Ltd", width: 4.5, length: 4.5, height: 3.5},
        {name: "Giant Party Castle", manufacturer: "Bouncy Castle Boys", width: 9.0, length: 9.0, height: 4.5},
        {name: "Princess Castle with Slide", manufacturer: "Jump4Joy Inflatables", width: 5.5, length: 7.0, height: 4.0, has_slide: true},
        {name: "Toddler Soft Play Centre", manufacturer: "Custom Inflatables UK", width: 6.0, length: 6.0, height: 2.5, is_totally_enclosed: true},
        {name: "Assault Course Challenge", manufacturer: "Inflatable World Ltd", width: 3.0, length: 12.0, height: 3.5, has_slide: true},
        {name: "Mega Slide Experience", manufacturer: "Airquee Manufacturing Ltd", width: 5.0, length: 15.0, height: 7.5, has_slide: true},
        {name: "Gladiator Duel Platform", manufacturer: "Happy Hop Europe", width: 6.0, length: 6.0, height: 1.5},
        {name: "Double Bungee Run", manufacturer: "Party Castle Manufacturers", width: 4.0, length: 10.0, height: 2.5}
      ]

      UNIT_COUNT.times do |i|
        config = unit_configs[i % unit_configs.length]
        unit = create_unit_from_config(user, config, i)
        # Make half of units have incomplete most recent inspection
        should_have_incomplete_inspection = i.even?
        create_inspections_for_unit(unit, user, config, has_incomplete_recent: should_have_incomplete_inspection)
      end
    end

    def create_unit_from_config(user, config, index)
      unit = user.units.create!(
        name: "#{config[:name]} ##{index + 1}",
        serial: "SEED-#{Date.current.year}-#{SecureRandom.hex(4).upcase}",
        description: generate_description(config[:name]),
        manufacturer: config[:manufacturer],
        model: "Model #{rand(100..999)}",
        owner: STEFAN_OWNER_NAMES.sample,
        is_seed: true
      )

      # Attach random castle image if available
      # For test environment, skip images as castle files don't exist
      if @castle_images.any? && !Rails.env.test?
        castle_image = @castle_images.sample
        # Create a new attachment - ActiveStorage will dedupe the blob automatically
        unit.photo.attach(
          io: StringIO.new(castle_image[:content]),
          filename: castle_image[:filename],
          content_type: "image/jpeg"
        )
      end

      unit
    end

    def generate_description(name)
      case name
      when /Castle/
        I18n.t("seed_data.descriptions.traditional_castle")
      when /Slide/
        I18n.t("seed_data.descriptions.combination_slide")
      when /Soft Play/
        I18n.t("seed_data.descriptions.soft_play")
      when /Assault Course/
        I18n.t("seed_data.descriptions.assault_course")
      when /Gladiator/
        I18n.t("seed_data.descriptions.gladiator")
      when /Bungee/
        I18n.t("seed_data.descriptions.bungee_run")
      else
        I18n.t("seed_data.descriptions.default")
      end
    end

    def create_inspections_for_unit(unit, user, config, has_incomplete_recent: false)
      offset_days = rand(INSPECTION_OFFSET_RANGE)

      INSPECTION_COUNT.times do |i|
        create_single_inspection(unit, user, config, offset_days, i, has_incomplete_recent)
      end
    end

    def create_single_inspection(unit, user, config, offset_days, index, has_incomplete_recent)
      inspection_date = calculate_inspection_date(offset_days, index)
      passed = determine_pass_status(index)
      is_complete = !(index == 0 && has_incomplete_recent)

      inspection = user.inspections.create!(
        build_inspection_attributes(unit, user, config, inspection_date, passed, is_complete)
      )

      create_assessments_for_inspection(inspection, unit, config, passed: passed)
    end

    def calculate_inspection_date(offset_days, index)
      days_ago = offset_days + (index * INSPECTION_INTERVAL_DAYS)
      Date.current - days_ago.days
    end

    def determine_pass_status(index)
      (index == 0) ? (rand < HIGH_PASS_RATE) : (rand < NORMAL_PASS_RATE)
    end

    def build_inspection_attributes(unit, user, config, inspection_date, passed, is_complete)
      {
        unit: unit,
        inspector_company: user.inspection_company,
        inspection_location: "#{TestDataHelpers.british_address}, #{TestDataHelpers.british_city}",
        inspection_date: inspection_date,
        complete_date: is_complete ? inspection_date.to_time + rand(INSPECTION_DURATION_RANGE).hours : nil,
        unique_report_number: generate_report_number(user.inspection_company, inspection_date),
        is_seed: true,
        passed: passed,
        risk_assessment: generate_risk_assessment(passed),
        # Copy dimensions from config
        width: config[:width],
        length: config[:length],
        height: config[:height],
        has_slide: config[:has_slide] || false,
        is_totally_enclosed: config[:is_totally_enclosed] || false
      }
    end

    def generate_report_number(company, date)
      company_prefix = company&.name&.split&.map(&:first)&.join&.upcase || "SEED"
      "#{company_prefix}-#{date.year}-#{SecureRandom.hex(4).upcase}"
    end

    def generate_risk_assessment(passed)
      if passed
        [
          "Unit inspected and found to be in good operational condition. All safety features functioning correctly. Suitable for continued use with standard supervision requirements.",
          "Comprehensive safety assessment completed. Unit meets all EN 14960:2019 requirements. No significant hazards identified. Regular maintenance schedule should be maintained.",
          "Risk assessment indicates low risk profile. All structural elements secure, adequate ventilation present, and safety markings clearly visible. Recommend continued operation with routine checks.",
          "Safety evaluation satisfactory. Anchoring system robust, materials show no signs of degradation. Unit provides safe environment for users within specified age and height limits.",
          "Full risk assessment completed with no critical issues identified. Minor wear noted on high-traffic areas but within acceptable limits. Unit certified safe for public use.",
          "Detailed inspection reveals unit maintains structural integrity. All seams intact, proper inflation pressure maintained. Risk level assessed as minimal with appropriate supervision.",
          "Unit passes comprehensive safety review. Emergency exits clearly marked and functional. Blower system operating within specifications. Low risk rating assigned.",
          "Risk evaluation complete. Unit demonstrates good stability under load conditions. Safety padding adequate where required. Suitable for continued commercial operation."
        ].sample
      else
        [
          "Risk assessment identifies multiple safety concerns requiring immediate attention. Unit should not be used until repairs completed and re-inspected. High risk rating assigned.",
          "Critical safety deficiencies noted during inspection. Structural integrity compromised in several areas. Unit poses unacceptable risk to users and must be withdrawn from service.",
          "Significant hazards identified including inadequate anchoring and material degradation. Risk level unacceptable for public use. Comprehensive repairs required before recertification.",
          "Safety assessment failed. Multiple non-conformances with EN 14960:2019 identified. Unit presents substantial risk of injury. Recommend immediate decommissioning or major refurbishment.",
          "High risk factors present including compromised seams and insufficient inflation. Unit unsafe for operation. Client advised to cease use pending extensive remedial work.",
          "Risk evaluation reveals dangerous conditions. Emergency exits partially obstructed, significant wear to load-bearing elements. Unit fails safety standards and requires urgent attention.",
          "Assessment indicates elevated risk profile due to equipment failures and material defects. Unit not suitable for use. Full replacement of critical components necessary."
        ].sample
      end
    end

    def create_assessments_for_inspection(inspection, unit, config, passed: true)
      create_anchorage_assessment(inspection, unit, passed)
      create_structure_assessment(inspection, unit, passed)
      create_materials_assessment(inspection, unit, passed)
      create_fan_assessment(inspection, unit, passed)
      create_user_height_assessment(inspection, unit, passed)
      create_slide_assessment(inspection, unit, passed) if config[:has_slide]
      create_enclosed_assessment(inspection, unit, passed) if config[:is_totally_enclosed]
    end

    def create_anchorage_assessment(inspection, unit, passed)
      inspection.anchorage_assessment.update!(
        num_low_anchors: rand(6..12),
        num_high_anchors: rand(4..8),
        num_anchors_pass: passed,
        anchor_accessories_pass: passed,
        anchor_degree_pass: passed,
        anchor_type_pass: passed,
        pull_strength_pass: passed,
        anchor_type_comment: passed ? nil : I18n.t("seed_data.assessment_comments.anchor_wear")
      )
    end

    def create_structure_assessment(inspection, unit, passed)
      inspection.structure_assessment.update!(
        seam_integrity_pass: passed,
        uses_lock_stitching_pass: passed,
        air_loss_pass: passed,
        straight_walls_pass: passed,
        sharp_edges_pass: passed,
        unit_stable_pass: passed,
        stitch_length_pass: passed,
        blower_tube_length_pass: passed,
        step_ramp_size_pass: passed,
        critical_fall_off_height_pass: passed,
        unit_pressure_pass: passed,
        trough_pass: passed,
        entrapment_pass: passed,
        markings_pass: passed,
        grounding_pass: passed,
        stitch_length: rand(8..12),
        unit_pressure: rand(1.0..3.0).round(1),
        blower_tube_length: rand(2.0..5.0).round(1),
        step_ramp_size: rand(200..400),
        critical_fall_off_height: rand(0.5..2.0).round(1),
        trough_depth: rand(0.1..0.5).round(1),
        trough_adjacent_panel_width: rand(0.3..1.0).round(1),
        seam_integrity_comment: passed ? "All seams in good condition" : "Minor thread loosening noted",
        uses_lock_stitching_comment: passed ? "Lock stitching intact throughout" : "Some lock stitching showing wear",
        stitch_length_comment: "Measured at regular intervals"
      )
    end

    def create_materials_assessment(inspection, unit, passed)
      inspection.materials_assessment.update!(
        ropes: rand(18..45),
        ropes_pass: passed,
        clamber_netting_pass: passed,
        retention_netting_pass: passed,
        zips_pass: passed,
        windows_pass: passed,
        artwork_pass: passed,
        thread_pass: passed,
        fabric_strength_pass: passed,
        fire_retardant_pass: passed,
        ropes_comment: passed ? nil : "Rope shows signs of wear",
        thread_comment: passed ? "Thread in good condition" : "Minor thread wear noted"
      )
    end

    def create_fan_assessment(inspection, unit, passed)
      inspection.fan_assessment.update!(
        blower_flap_pass: passed,
        blower_finger_pass: passed,
        blower_visual_pass: passed,
        pat_pass: passed,
        blower_serial: "FAN-#{rand(1000..9999)}",
        fan_size_type: passed ? "Fan operating correctly at optimal pressure" : "Fan requires servicing",
        blower_flap_comment: passed ? "Flap mechanism functioning correctly" : "Flap sticking occasionally",
        blower_finger_comment: passed ? "Guard secure, no finger trap hazards" : "Guard needs tightening",
        blower_visual_comment: passed ? "Visual inspection satisfactory" : "Some wear visible on housing",
        pat_comment: passed ? "PAT test valid until #{(Date.current + 6.months).strftime("%B %Y")}" : "PAT test overdue"
      )
    end

    def create_user_height_assessment(inspection, unit, passed)
      play_area_length = inspection.length * 0.8
      play_area_width = inspection.width * 0.8

      inspection.user_height_assessment.update!(
        containing_wall_height: rand(1.0..2.0).round(1),
        platform_height: rand(0.5..1.5).round(1),
        tallest_user_height: rand(1.2..1.8).round(1),
        users_at_1000mm: rand(0..5),
        users_at_1200mm: rand(2..8),
        users_at_1500mm: rand(4..10),
        users_at_1800mm: rand(2..6),
        play_area_length: play_area_length,
        play_area_width: play_area_width,
        negative_adjustment: rand(0..2.0).round(1),
        permanent_roof: false,
        tallest_user_height_comment: passed ? "Capacity within safe limits based on EN 14960:2019" : "Review user capacity - exceeds recommended limits",
        containing_wall_height_comment: "Measured from base to top of wall",
        platform_height_comment: "Platform height acceptable for age group",
        play_area_length_comment: "Effective play area after deducting obstacles",
        play_area_width_comment: "Width measured at narrowest point"
      )
    end

    def create_slide_assessment(inspection, unit, passed)
      inspection.slide_assessment.update!(
        slide_platform_height: rand(2.0..6.0).round(1),
        slide_wall_height: rand(1.0..2.0).round(1),
        runout: rand(1.5..3.0).round(1),
        slide_first_metre_height: rand(0.3..0.8).round(1),
        slide_beyond_first_metre_height: rand(0.8..1.5).round(1),
        clamber_netting_pass: passed,
        runout_pass: passed,
        slip_sheet_pass: passed,
        slide_permanent_roof: false,
        slide_platform_height_comment: passed ? "Platform height compliant with EN 14960:2019" : "Platform height exceeds recommended limits",
        slide_wall_height_comment: "Wall height measured from slide bed",
        runout_comment: passed ? "Runout area clear and adequate" : "Runout area needs extending",
        clamber_netting_comment: passed ? "Netting secure with no gaps" : "Some gaps in netting need attention",
        slip_sheet_comment: passed ? "Slip sheet in good condition" : "Slip sheet showing wear"
      )
    end

    def create_enclosed_assessment(inspection, unit, passed)
      inspection.enclosed_assessment.update!(
        exit_number: rand(1..3),
        exit_number_pass: passed,
        exit_sign_always_visible_pass: passed,
        exit_sign_visible_pass: passed,
        exit_number_comment: passed ? "Number of exits compliant with unit size" : "Additional exit required",
        exit_sign_always_visible_comment: passed ? "Exit signs visible from all points" : "Exit signs obscured from some angles",
        exit_sign_visible_comment: passed ? "All exits clearly marked with illuminated signage" : "Exit signage needs improvement - not clearly visible"
      )
    end
  end
end
