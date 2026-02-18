# typed: strict

class SeedDataService
  extend T::Sig

  CASTLE_IMAGE_COUNT = T.let(5, Integer)
  UNIT_COUNT = T.let(20, Integer)
  INSPECTION_COUNT = T.let(5, Integer)
  INSPECTION_INTERVAL_DAYS = T.let(364, Integer)
  INSPECTION_OFFSET_RANGE = T.let(0..365, T::Range[Integer])
  INSPECTION_DURATION_RANGE = T.let(1..4, T::Range[Integer])
  HIGH_PASS_RATE = T.let(0.95, Float)
  NORMAL_PASS_RATE = T.let(0.85, Float)

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

  class << self
    extend T::Sig

    sig { params(user: User, unit_count: Integer, inspection_count: Integer).returns(T::Boolean) }
    def add_seeds_for_user(user, unit_count: UNIT_COUNT, inspection_count: INSPECTION_COUNT)
      raise "User already has seed data" if user.has_seed_data?

      ActiveRecord::Base.transaction do
        Rails.logger.info I18n.t("seed_data.logging.starting_creation", user_id: user.id)
        ensure_castle_blobs_exist
        Rails.logger.info I18n.t("seed_data.logging.castle_images_found", count: @castle_images.size)
        create_seed_units_for_user(user, unit_count, inspection_count)
        Rails.logger.info I18n.t("seed_data.logging.creation_completed")
      end
      true
    end

    sig { params(user: User).returns(T::Boolean) }
    def delete_seeds_for_user(user)
      ActiveRecord::Base.transaction do
        # Delete inspections first (due to foreign key constraints)
        user.inspections.seed_data.destroy_all
        # Then delete units with preloaded attachments to avoid N+1
        user.units.seed_data.includes(photo_attachment: :blob, cached_pdf_attachment: :blob).destroy_all
      end
      true
    end

    private

    sig { void }
    def ensure_castle_blobs_exist
      @castle_images = T.let([], T::Array[T::Hash[Symbol, T.untyped]])

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

    sig { params(user: User, unit_count: Integer, inspection_count: Integer).void }
    def create_seed_units_for_user(user, unit_count, inspection_count)
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

      # Pre-generate all unit IDs to avoid N+1 queries
      unit_ids = generate_unit_ids_batch(user, unit_count)

      # Pre-load existing unit IDs to avoid repeated existence checks
      existing_ids = user.units.pluck(:id).to_set

      unit_count.times do |i|
        config = unit_configs[i % unit_configs.length]
        unit = create_unit_from_config(user, config, i, unit_ids[i], existing_ids)
        # Make half of units have incomplete most recent inspection
        should_have_incomplete_inspection = i.even?
        create_inspections_for_unit(unit, user, config, inspection_count, has_incomplete_recent: should_have_incomplete_inspection)
      end
    end

    sig { params(user: User, count: Integer).returns(T::Array[String]) }
    def generate_unit_ids_batch(user, count)
      ids = []
      existing_ids = user.units.pluck(:id).to_set

      # When unit_badges is enabled, create badges for seed units
      if Rails.configuration.units.badges_enabled
        batch = BadgeBatch.create!(
          note: "Seed data badges for #{user.email}"
        )

        count.times do
          loop do
            id = SecureRandom.alphanumeric(CustomIdGenerator::ID_LENGTH).upcase
            unless existing_ids.include?(id) || Badge.exists?(id: id)
              Badge.create!(id: id, badge_batch: batch)
              ids << id
              existing_ids << id
              break
            end
          end
        end
      else
        # Original behavior when unit_badges is disabled
        count.times do
          loop do
            id = SecureRandom.alphanumeric(CustomIdGenerator::ID_LENGTH).upcase
            unless existing_ids.include?(id)
              ids << id
              existing_ids << id
              break
            end
          end
        end
      end

      ids
    end

    sig { params(user: User, config: T::Hash[Symbol, T.untyped], index: Integer, unit_id: String, existing_ids: T::Set[String]).returns(Unit) }
    def create_unit_from_config(user, config, index, unit_id, existing_ids)
      # Always use the unit_id - when unit_badges is enabled, generate_unit_ids_batch
      # creates badges for these IDs
      unit = user.units.build(
        id: unit_id,
        name: "#{config[:name]} ##{index + 1}",
        serial: "SEED-#{Date.current.year}-#{SecureRandom.hex(4).upcase}",
        description: generate_description(config[:name]),
        manufacturer: config[:manufacturer],
        is_seed: true
      )
      unit.save!

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

    sig { params(name: String).returns(String) }
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

    sig { params(unit: Unit, user: User, config: T::Hash[Symbol, T.untyped], inspection_count: Integer, has_incomplete_recent: T::Boolean).void }
    def create_inspections_for_unit(unit, user, config, inspection_count, has_incomplete_recent: false)
      offset_days = rand(INSPECTION_OFFSET_RANGE)

      inspection_count.times do |i|
        create_single_inspection(unit, user, config, offset_days, i, has_incomplete_recent)
      end
    end

    sig { params(unit: Unit, user: User, config: T::Hash[Symbol, T.untyped], offset_days: Integer, index: Integer, has_incomplete_recent: T::Boolean).void }
    def create_single_inspection(unit, user, config, offset_days, index, has_incomplete_recent)
      inspection_date = calculate_inspection_date(offset_days, index)
      passed = determine_pass_status(index)
      is_complete = !(index == 0 && has_incomplete_recent)

      inspection = user.inspections.create!(
        build_inspection_attributes(unit, user, config, inspection_date, passed, is_complete)
      )

      create_assessments_for_inspection(inspection, unit, config, passed: passed)
    end

    sig { params(offset_days: Integer, index: Integer).returns(Date) }
    def calculate_inspection_date(offset_days, index)
      days_ago = offset_days + (index * INSPECTION_INTERVAL_DAYS)
      Date.current - days_ago.days
    end

    sig { params(index: Integer).returns(T::Boolean) }
    def determine_pass_status(index)
      (index == 0) ? (rand < HIGH_PASS_RATE) : (rand < NORMAL_PASS_RATE)
    end

    sig { params(unit: Unit, user: User, config: T::Hash[Symbol, T.untyped], inspection_date: Date, passed: T::Boolean, is_complete: T::Boolean).returns(T::Hash[Symbol, T.untyped]) }
    def build_inspection_attributes(unit, user, config, inspection_date, passed, is_complete)
      {
        unit: unit,
        inspector_company: user.inspection_company,
        inspection_date: inspection_date,
        complete_date: is_complete ?
          inspection_date.to_time + rand(INSPECTION_DURATION_RANGE).hours :
          nil,
        is_seed: true,
        passed: is_complete ? passed : nil,
        risk_assessment: generate_risk_assessment(passed),
        operator: STEFAN_OWNER_NAMES.sample,
        # Copy dimensions from config
        width: config[:width],
        length: config[:length],
        height: config[:height],
        has_slide: config[:has_slide] || false,
        is_totally_enclosed: config[:is_totally_enclosed] || false,
        indoor_only: [true, false].sample
      }
    end

    sig { params(passed: T::Boolean).returns(String) }
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

    sig { params(inspection: Inspection, unit: Unit, config: T::Hash[Symbol, T.untyped], passed: T::Boolean).void }
    def create_assessments_for_inspection(inspection, unit, config, passed: true)
      is_incomplete = inspection.complete_date.nil?

      inspection.each_applicable_assessment do |assessment_key, assessment_class, _|
        assessment_type = assessment_key.to_s.sub(/_assessment$/, "")

        create_assessment(
          inspection,
          assessment_key,
          assessment_type,
          passed,
          is_incomplete
        )
      end
    end

    sig { params(inspection: Inspection, assessment_key: Symbol, assessment_type: String, passed: T::Boolean, is_incomplete: T::Boolean).void }
    def create_assessment(
      inspection,
      assessment_key,
      assessment_type,
      passed,
      is_incomplete
    )
      fields = SeedData.send("#{assessment_type}_fields", passed: passed)

      if assessment_key == :user_height_assessment && inspection.length && inspection.width
        fields[:play_area_length] = inspection.length * 0.8
        fields[:play_area_width] = inspection.width * 0.8
      end

      fields = randomly_remove_fields(fields, is_incomplete)
      inspection.send(assessment_key).update!(fields)
    end

    sig { params(fields: T::Hash[Symbol, T.untyped], is_incomplete: T::Boolean).returns(T::Hash[Symbol, T.untyped]) }
    def randomly_remove_fields(fields, is_incomplete)
      return fields unless is_incomplete
      return fields unless rand(0..1) == 0 # empty 50% of assessments
      fields.keys.each { |field| fields[field] = nil }
      fields
    end
  end
end
