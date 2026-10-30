# typed: false

require "rails_helper"

RSpec.describe AssessmentCompletion, type: :model do
  let(:inspection) { create(:inspection) }
  let(:assessment) { inspection.user_height_assessment }
  let(:incomplete) { assessment.incomplete_fields }
  let(:pass_fields) do
    assessment.class.column_names
      .select { |col| col.end_with?("_pass") }
      .map(&:to_sym)
  end

  describe "#incomplete_fields" do
    context "with a new assessment" do
      it "returns all required fields as incomplete" do
        expect(incomplete).to include(
          :containing_wall_height
        )
        pass_fields.each do |field|
          expect(incomplete).to include(field)
        end
      end
    end

    context "with a partially complete assessment" do
      before do
        assessment.update!(
          containing_wall_height: 2.5
        )
      end

      it "only returns incomplete fields" do
        expect(incomplete).not_to include(
          :containing_wall_height
        )
        pass_fields.each do |field|
          expect(incomplete).to include(field)
        end
      end
    end

    context "with a complete assessment" do
      before do
        assessment.update!(
          maximum_user_height: 1.8,
          containing_wall_height: 2.5,
          users_at_1000mm: 5,
          users_at_1200mm: 10,
          users_at_1500mm: 8,
          users_at_1800mm: 2,
          custom_user_height_comment: "Test comments",
          play_area_length: 10.0,
          play_area_width: 8.0,
          negative_adjustment: 0.0
        )
      end

      it "returns an empty array" do
        expect(incomplete).to be_empty
        expect(assessment).to be_complete
      end
    end

    context "with fields configured as optional" do
      let(:assessment) { inspection.structure_assessment }

      it "does not return their values or checks as incomplete" do
        optional_fields = %i[
          straight_walls_pass
          trough_adjacent_panel_width
          trough_depth
        ]

        expect(assessment.incomplete_fields).not_to include(*optional_fields)
      end
    end

    context "with structure fields marked as not applicable" do
      let(:assessment) { inspection.structure_assessment }

      it "requires the value when the check is not answered" do
        expect(assessment.incomplete_fields)
          .to include(:step_ramp_size, :step_ramp_size_pass)
      end

      it "does not require the value when the check is na" do
        assessment.update!(
          step_ramp_size_pass: :na,
          platform_height_pass: :na,
          critical_fall_off_height_pass: :na
        )

        expect(assessment.incomplete_fields).not_to include(
          :step_ramp_size,
          :step_ramp_size_pass,
          :platform_height,
          :platform_height_pass,
          :critical_fall_off_height,
          :critical_fall_off_height_pass
        )
      end
    end

    context "with optional user count fields" do
      it "does not return blank height counts as incomplete" do
        optional_fields = %i[
          users_at_1000mm
          users_at_1200mm
          users_at_1500mm
          users_at_1800mm
        ]

        expect(assessment.incomplete_fields).not_to include(*optional_fields)
      end
    end

    context "with optional comments and explicit outcomes" do
      let(:assessment) { inspection.materials_assessment }

      it "accepts failed and N/A answers without comments or N/A values" do
        assessment.assign_attributes(
          ropes_pass: "na", fabric_strength_pass: "fail",
          fire_retardant_pass: "pass", thread_pass: "pass",
          retention_netting_pass: "na", zips_pass: "na",
          windows_pass: "na", artwork_pass: "na"
        )

        expect(assessment.ropes).to be_nil
        expect(assessment).to be_complete
      end

      it "does not treat a blank outcome as an answer" do
        assessment.ropes_pass = ""

        expect(assessment.incomplete_fields).to include(:ropes_pass)
      end
    end

    context "with a textual answer" do
      let(:unit) { create(:unit, unit_type: :catch_bed) }
      let(:inspection) { create(:inspection, unit: unit) }
      let(:assessment) { inspection.catch_bed_assessment }

      it "treats whitespace as incomplete rather than a recorded answer" do
        assessment.type_of_unit = " "

        expect(assessment.incomplete_fields).to include(:type_of_unit)
      end
    end

    context "with inapplicable component checks" do
      let(:unit) { create(:unit, unit_type: :play_zone) }
      let(:inspection) do
        create(:inspection, unit: unit, has_ball_pool: false,
          has_air_jugglers: false, has_slide: false)
      end
      let(:assessment) { inspection.play_zone_assessment }

      it "does not require hidden components or their measurements" do
        expect(assessment.incomplete_fields).not_to include(
          :balls_pass, :air_juggler_pass, :ball_pool_depth,
          :ball_pool_depth_pass, :slide_gradient, :slide_gradient_pass
        )
      end
    end

    context "with N/A age markings" do
      let(:unit) { create(:unit, unit_type: :inflatable_ball_pool) }
      let(:inspection) { create(:inspection, unit: unit) }
      let(:assessment) { inspection.ball_pool_assessment }

      it "exempts both associated age limits" do
        expect(assessment.incomplete_fields)
          .to include(:minimum_age, :maximum_age)
        assessment.age_range_marking_pass = "na"

        expect(assessment.incomplete_fields)
          .not_to include(:minimum_age, :maximum_age)
      end
    end

    context "with grouped N/A wall checks" do
      let(:unit) { create(:unit, unit_type: :bungee_run) }
      let(:inspection) { create(:inspection, unit: unit) }
      let(:assessment) { inspection.bungee_assessment }

      it "exempts measurements in the associated wall group only" do
        assessment.rear_wall_pass = "na"

        expect(assessment.incomplete_fields)
          .not_to include(:rear_wall_height, :rear_wall_thickness)
        expect(assessment.incomplete_fields)
          .to include(:side_wall_height, :side_wall_length)
      end
    end
  end

  describe "#incomplete_fields_grouped" do
    let(:inspection) { create(:inspection) }
    let(:assessment) { inspection.materials_assessment }

    context "when both value and pass fields are missing" do
      before do
        assessment.update!(ropes: nil, ropes_pass: nil)
      end

      it "groups them together under the base field" do
        grouped = assessment.incomplete_fields_grouped

        expect(grouped[:ropes]).to be_present
        expect(grouped[:ropes][:fields]).to contain_exactly(:ropes, :ropes_pass)
        expect(grouped[:ropes][:partial]).to eq(:number_pass_fail_na_comment)
      end
    end

    context "when only pass field is missing" do
      before do
        assessment.update!(ropes: 10, ropes_pass: nil)
      end

      it "returns only the pass field" do
        grouped = assessment.incomplete_fields_grouped

        expect(grouped[:ropes_pass]).to be_present
        expect(grouped[:ropes_pass][:fields]).to eq([:ropes_pass])
      end
    end

    context "when only value field is missing" do
      before do
        assessment.update!(ropes: nil, ropes_pass: "pass")
      end

      it "requires the measurement but not another outcome" do
        expect(assessment.incomplete_fields).to include(:ropes)
        expect(assessment.incomplete_fields).not_to include(:ropes_pass)
      end

      it "returns only the value field" do
        grouped = assessment.incomplete_fields_grouped

        expect(grouped[:ropes]).to be_present
        expect(grouped[:ropes][:fields]).to eq([:ropes])
      end
    end

    context "when pass field is set to NA" do
      before do
        assessment.update!(ropes: nil, ropes_pass: "na")
      end

      it "does not include the value field in incomplete fields" do
        expect(assessment.incomplete_fields).not_to include(:ropes)
      end

      it "does not include the pass field in incomplete fields (NA is a valid selection)" do
        expect(assessment.incomplete_fields).not_to include(:ropes_pass)
      end

      it "does not show either field as incomplete in grouped results" do
        grouped = assessment.incomplete_fields_grouped
        expect(grouped[:ropes]).to be_nil
        expect(grouped[:ropes_pass]).to be_nil
      end
    end

    context "when a pass-only field is set to NA" do
      before do
        assessment.update!(retention_netting_pass: "na")
      end

      it "does not include the field in incomplete fields (NA is a valid selection)" do
        expect(assessment.incomplete_fields).not_to include(:retention_netting_pass)
      end
    end
  end

  describe "outcome storage" do
    let(:assessment) { inspection.anchorage_assessment }

    it "stores Fail, Pass and N/A as 0, 1 and 2 without changing blanks" do
      {"fail" => 0, "pass" => 1, "na" => 2, nil => nil}.each do |answer, raw|
        assessment.update!(pull_strength_pass: answer)
        assessment.reload

        expect(assessment.pull_strength_pass).to eq(answer)
        expect(assessment.pull_strength_pass_before_type_cast).to eq(raw)
      end
    end

    it "exposes only the three outcome states without boolean aliases" do
      states = assessment.class.defined_enums.fetch("pull_strength_pass")

      expect(states).to eq("fail" => 0, "pass" => 1, "na" => 2)
      expect { assessment.pull_strength_pass = true }
        .to raise_error(ArgumentError)
    end

    it "identifies only originally boolean outcomes for historical exports" do
      klass = Assessments::MaterialsAssessment

      expect(klass.legacy_boolean_outcome_fields).to contain_exactly(
        :thread_pass, :fabric_strength_pass, :fire_retardant_pass
      )
    end
  end
end
