# frozen_string_literal: true

require "rails_helper"

RSpec.describe JsonSerializerService do
  let(:user) { create(:user) }

  describe ".serialize_unit" do
    let(:unit) { create(:unit, user: user) }

    it "includes all public fields using reflection" do
      json = JsonSerializerService.serialize_unit(unit)

      # Get expected fields using same reflection as service
      expected_fields = Unit.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

      # Check all expected fields are present (if they have values)
      expected_fields.each do |field|
        value = unit.send(field)
        expect(json).to have_key(field.to_sym), "Expected field '#{field}' to be in JSON" if value.present?
      end

      # Check excluded fields are not present
      PublicFieldFiltering::EXCLUDED_FIELDS.each do |field|
        expect(json).not_to have_key(field.to_sym), "Field '#{field}' should be excluded from JSON"
      end
    end

    it "excludes sensitive unit fields" do
      json = JsonSerializerService.serialize_unit(unit)

      expect(json).not_to have_key(:user_id)
      expect(json).not_to have_key(:created_at)
      expect(json).not_to have_key(:updated_at)
    end

    it "includes URLs" do
      json = JsonSerializerService.serialize_unit(unit)

      expect(json[:urls]).to be_present
      expect(json[:urls][:report_pdf]).to include("/units/#{unit.id}.pdf")
      expect(json[:urls][:report_json]).to include("/units/#{unit.id}.json")
      expect(json[:urls][:qr_code]).to include("/units/#{unit.id}.png")
    end

    context "with inspection history" do
      let!(:completed_inspection) { create(:inspection, :completed, user: user, unit: unit, passed: true) }
      let!(:draft_inspection) { create(:inspection, user: user, unit: unit, complete_date: nil) }

      it "includes only completed inspections" do
        json = JsonSerializerService.serialize_unit(unit)

        expect(json[:inspection_history].length).to eq(1)
        expect(json[:total_inspections]).to eq(1)
        expect(json[:last_inspection_passed]).to eq(true)

        # Verify no IDs are included
        expect(json[:inspection_history].first).not_to have_key(:id)
        expect(json[:inspection_history].first).to have_key(:unique_report_number)
      end
    end

    context "when include_inspections is false" do
      it "excludes inspection history" do
        create(:inspection, :completed, user: user, unit: unit)

        json = JsonSerializerService.serialize_unit(unit, include_inspections: false)

        expect(json).not_to have_key(:inspection_history)
        expect(json).not_to have_key(:total_inspections)
      end
    end
  end

  describe ".serialize_inspection" do
    let(:unit) { create(:unit, user: user) }
    let(:inspection) { create(:inspection, :completed, user: user, unit: unit) }

    it "includes all public fields using reflection" do
      json = JsonSerializerService.serialize_inspection(inspection)

      # Get expected fields using same reflection as service
      expected_fields = Inspection.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

      # Check all expected fields are present (if they have values)
      expected_fields.each do |field|
        value = inspection.send(field)
        expect(json).to have_key(field.to_sym), "Expected field '#{field}' to be in JSON" if value.present?
      end

      # Check excluded fields are not present
      PublicFieldFiltering::EXCLUDED_FIELDS.each do |field|
        expect(json).not_to have_key(field.to_sym), "Field '#{field}' should be excluded from JSON"
      end
    end

    it "excludes sensitive inspection fields" do
      json = JsonSerializerService.serialize_inspection(inspection)

      expect(json).not_to have_key(:user_id)
      expect(json).not_to have_key(:pdf_last_accessed_at)
    end

    it "includes inspector info but not company info" do
      json = JsonSerializerService.serialize_inspection(inspection)

      expect(json[:inspector]).to be_present
      expect(json[:inspector][:name]).to eq(inspection.user.name)
      expect(json[:inspector][:rpii_inspector_number]).to eq(inspection.user.rpii_inspector_number)
      expect(json).not_to have_key(:inspector_company)
    end

    it "includes unit info" do
      json = JsonSerializerService.serialize_inspection(inspection)

      expect(json[:unit]).to be_present
      expect(json[:unit][:id]).to eq(unit.id)
      # has_slide and is_totally_enclosed are now on inspection, not unit
      expect(json[:has_slide]).to eq(true)
      expect(json[:is_totally_enclosed]).to eq(true)
    end

    context "with assessments" do
      before do
        # Update existing assessments with specific test data
        inspection.structure_assessment.update!(unit_pressure: 5.0)
        inspection.anchorage_assessment.update!(num_low_anchors_comment: "Private comment")
        inspection.materials_assessment.update!(ropes_comment: "Private comment")
        inspection.fan_assessment.update!(blower_serial: "PRIVATE123")
        inspection.enclosed_assessment.update!(exit_number_comment: "Private comment")
      end

      it "includes all assessments with public fields only" do
        json = JsonSerializerService.serialize_inspection(inspection)

        expect(json[:assessments]).to be_present

        # Check each assessment type
        %i[user_height_assessment structure_assessment anchorage_assessment
          materials_assessment fan_assessment enclosed_assessment slide_assessment].each do |assessment_type|
          expect(json[:assessments]).to have_key(assessment_type)
        end
      end

      it "includes all assessment fields except system fields" do
        json = JsonSerializerService.serialize_inspection(inspection)

        # StructureAssessment should include all fields
        structure = json[:assessments][:structure_assessment]
        expect(structure).to have_key(:unit_pressure)

        # AnchorageAssessment should include all comment fields
        anchorage = json[:assessments][:anchorage_assessment]
        expect(anchorage).to have_key(:num_low_anchors_comment)
        expect(anchorage).to have_key(:num_high_anchors_comment)
        expect(anchorage).to have_key(:anchor_accessories_comment)

        # MaterialsAssessment should include all fields
        materials = json[:assessments][:materials_assessment]
        expect(materials).to have_key(:ropes_comment)
        expect(materials).to have_key(:thread_comment)

        # FanAssessment should include all fields
        fan = json[:assessments][:fan_assessment]
        expect(fan).to have_key(:blower_serial)
        expect(fan).to have_key(:pat_comment)

        # EnclosedAssessment should include all fields
        enclosed = json[:assessments][:enclosed_assessment]
        expect(enclosed).to have_key(:exit_number_comment)
        expect(enclosed).to have_key(:exit_sign_always_visible_comment)
      end

      it "includes public assessment fields using reflection" do
        json = JsonSerializerService.serialize_inspection(inspection)

        # Test UserHeightAssessment fields as example
        user_height = json[:assessments][:user_height_assessment]

        # Get expected fields
        excluded = PublicFieldFiltering::EXCLUDED_FIELDS
        expected_fields = Assessments::UserHeightAssessment.column_names - excluded

        expected_fields.each do |field|
          value = inspection.user_height_assessment.send(field)
          if value.present?
            expect(user_height).to have_key(field.to_sym), "Expected assessment field '#{field}' to be in JSON"
          end
        end
      end
    end

    context "when unit doesn't have slide" do
      let(:unit_no_slide) { create(:unit, user: user) }
      let(:inspection_no_slide) { create(:inspection, :completed, :without_slide, user: user, unit: unit_no_slide) }

      it "excludes slide assessment" do
        json = JsonSerializerService.serialize_inspection(inspection_no_slide)

        expect(json[:assessments]).not_to have_key(:slide_assessment)
      end
    end
  end

  describe "field coverage completeness" do
    it "covers all Unit fields" do
      unit = create(:unit, :with_all_fields, user: user)
      json = JsonSerializerService.serialize_unit(unit)

      # Count included fields
      included_fields = Unit.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

      # Verify we're including the expected number of fields
      expect(included_fields.count).to eq(8)

      # Verify critical fields are included
      %w[name serial manufacturer owner description model].each do |field|
        expect(json).to have_key(field.to_sym)
      end
    end

    it "covers all Inspection fields" do
      inspection = create(:inspection, :completed, user: user)
      json = JsonSerializerService.serialize_inspection(inspection)

      # Count included fields
      included_fields = Inspection.column_names - PublicFieldFiltering::EXCLUDED_FIELDS

      # Verify we're including the expected number of fields
      expect(included_fields.count).to eq(15) # Actual count of included fields (includes new inspection_type field and indoor_only)

      # Verify critical fields are included
      %w[inspection_date inspection_location passed complete_date].each do |field|
        expect(json).to have_key(field.to_sym)
      end

      # Verify unique_report_number is NOT included
      expect(json).not_to have_key(:unique_report_number)
    end
  end
end
