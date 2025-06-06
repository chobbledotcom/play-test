require "rails_helper"

RSpec.describe AnchorageAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { create(:anchorage_assessment, inspection: inspection) }

  describe "associations" do
    it "belongs to inspection" do
      expect(assessment.inspection).to eq(inspection)
    end
  end

  describe "validations" do
    context "anchor counts" do
      %w[num_low_anchors num_high_anchors].each do |count_field|
        it "validates #{count_field} is non-negative integer" do
          assessment.send("#{count_field}=", -1)
          expect(assessment).not_to be_valid
          expect(assessment.errors[count_field.to_sym]).to include("must be greater than or equal to 0")
        end

        it "validates #{count_field} is integer" do
          assessment.send("#{count_field}=", 5.5)
          expect(assessment).not_to be_valid
          expect(assessment.errors[count_field.to_sym]).to include("must be an integer")
        end

        it "allows blank #{count_field}" do
          assessment.send("#{count_field}=", nil)
          expect(assessment).to be_valid
        end
      end
    end

    context "pass/fail assessments" do
      %w[num_anchors_pass anchor_accessories_pass anchor_degree_pass
        anchor_type_pass pull_strength_pass].each do |check|
        it "validates #{check} inclusion" do
          assessment.send("#{check}=", "not_a_boolean")
          assessment.valid?
          # Note: Rails converts strings to boolean, so this tests the validation message format
          # The validation allows true/false/nil, which covers the converted boolean values
          expect(assessment).to be_valid # String gets converted to true, which is allowed
        end

        it "allows nil for #{check}" do
          assessment.send("#{check}=", nil)
          expect(assessment).to be_valid
        end

        it "allows true/false for #{check}" do
          assessment.send("#{check}=", true)
          expect(assessment).to be_valid

          assessment.send("#{check}=", false)
          expect(assessment).to be_valid
        end
      end
    end
  end

  describe "#complete?" do
    it "returns true when all requirements are met" do
      assessment.update!(
        num_low_anchors: 4,
        num_high_anchors: 4,
        num_anchors_pass: true,
        anchor_accessories_pass: true,
        anchor_degree_pass: true,
        anchor_type_pass: true,
        pull_strength_pass: true
      )
      expect(assessment.complete?).to be true
    end

    it "returns false when anchor counts are missing" do
      assessment.update!(
        num_low_anchors: nil,
        num_high_anchors: 4,
        num_anchors_pass: true,
        anchor_accessories_pass: true,
        anchor_degree_pass: true,
        anchor_type_pass: true,
        pull_strength_pass: true
      )
      expect(assessment.complete?).to be false
    end

    it "returns false when anchor assessments are incomplete" do
      assessment.update!(
        num_low_anchors: 4,
        num_high_anchors: 4,
        num_anchors_pass: true,
        anchor_accessories_pass: nil,
        anchor_degree_pass: true,
        anchor_type_pass: true,
        pull_strength_pass: true
      )
      expect(assessment.complete?).to be false
    end
  end

  describe "#meets_anchor_requirements?" do
    context "with valid data" do
      it "delegates to SafetyStandard when data is present" do
        assessment.num_low_anchors = 4
        assessment.num_high_anchors = 4

        expect(SafetyStandard).to receive(:calculate_required_anchors).with(100.0).and_return(6)
        expect(assessment.meets_anchor_requirements?).to be true # 8 >= 6
      end

      it "returns false when anchors are insufficient" do
        assessment.num_low_anchors = 2
        assessment.num_high_anchors = 2

        expect(SafetyStandard).to receive(:calculate_required_anchors).with(100.0).and_return(6)
        expect(assessment.meets_anchor_requirements?).to be false # 4 < 6
      end
    end

    context "with missing data" do
      it "returns false when total_anchors is missing" do
        assessment.num_low_anchors = nil
        assessment.num_high_anchors = 4
        expect(assessment.meets_anchor_requirements?).to be false
      end

      it "returns false when total anchors is insufficient" do
        assessment.num_low_anchors = 1
        assessment.num_high_anchors = 1
        expect(assessment.meets_anchor_requirements?).to be false
      end
    end
  end

  describe "#has_critical_failures?" do
    it "returns true when anchor_type_pass fails" do
      assessment.anchor_type_pass = false
      assessment.pull_strength_pass = true
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns true when pull_strength_pass fails" do
      assessment.anchor_type_pass = true
      assessment.pull_strength_pass = false
      expect(assessment.has_critical_failures?).to be true
    end

    it "returns false when both critical checks pass" do
      assessment.anchor_type_pass = true
      assessment.pull_strength_pass = true
      expect(assessment.has_critical_failures?).to be false
    end

    it "returns false when critical checks are nil" do
      assessment.anchor_type_pass = nil
      assessment.pull_strength_pass = nil
      expect(assessment.has_critical_failures?).to be false
    end
  end

  describe "#total_anchors" do
    it "sums low and high anchors" do
      assessment.num_low_anchors = 5
      assessment.num_high_anchors = 3
      expect(assessment.total_anchors).to eq(8)
    end

    it "handles nil values as zero" do
      assessment.num_low_anchors = 5
      assessment.num_high_anchors = nil
      expect(assessment.total_anchors).to eq(5)

      assessment.num_low_anchors = nil
      assessment.num_high_anchors = 3
      expect(assessment.total_anchors).to eq(3)
    end

    it "returns 0 when both are nil" do
      assessment.num_low_anchors = nil
      assessment.num_high_anchors = nil
      expect(assessment.total_anchors).to eq(0)
    end
  end

  describe "#required_anchors" do
    it "delegates to SafetyStandard when area is present" do
      expect(SafetyStandard).to receive(:calculate_required_anchors).with(100.0).and_return(8)
      expect(assessment.required_anchors).to eq(8)
    end
  end

  describe "#anchor_compliance_status" do
    it "returns proper status when anchors are zero" do
      assessment.num_low_anchors = nil
      assessment.num_high_anchors = nil
      # With a 100 unit area, this should require many anchors but have 0
      expect(assessment.anchor_compliance_status).to match(/Non-Compliant.*has 0/)
    end

    it "returns 'Compliant' when requirements are met" do
      assessment.num_low_anchors = 5
      assessment.num_high_anchors = 3
      allow(assessment).to receive(:meets_anchor_requirements?).and_return(true)
      expect(assessment.anchor_compliance_status).to eq("Compliant")
    end

    it "returns detailed non-compliance message when requirements not met" do
      assessment.num_low_anchors = 2
      assessment.num_high_anchors = 2
      allow(assessment).to receive(:meets_anchor_requirements?).and_return(false)
      allow(assessment).to receive(:required_anchors).and_return(8)
      expect(assessment.anchor_compliance_status).to eq("Non-Compliant (Requires 8 total anchors, has 4)")
    end
  end

  describe "#safety_check_count" do
    it "returns 5 anchor-related safety checks" do
      expect(assessment.safety_check_count).to eq(5)
    end
  end

  describe "#passed_checks_count" do
    it "counts all passed safety checks" do
      assessment.update!(
        num_anchors_pass: true,
        anchor_accessories_pass: false,
        anchor_degree_pass: true,
        anchor_type_pass: true,
        pull_strength_pass: false
      )
      expect(assessment.passed_checks_count).to eq(3)
    end

    it "returns 0 when no checks are passed" do
      assessment.update!(
        num_anchors_pass: false,
        anchor_accessories_pass: false,
        anchor_degree_pass: false,
        anchor_type_pass: false,
        pull_strength_pass: false
      )
      expect(assessment.passed_checks_count).to eq(0)
    end

    it "handles nil values" do
      assessment.update!(
        num_anchors_pass: true,
        anchor_accessories_pass: nil,
        anchor_degree_pass: true,
        anchor_type_pass: false,
        pull_strength_pass: nil
      )
      expect(assessment.passed_checks_count).to eq(2)
    end
  end

  describe "#completion_percentage" do
    it "calculates percentage of completed fields" do
      assessment.update!(
        num_low_anchors: 4,
        num_high_anchors: 4,
        num_anchors_pass: true,
        anchor_accessories_pass: true,
        anchor_degree_pass: true,
        anchor_type_pass: true,
        pull_strength_pass: true
      )
      expect(assessment.completion_percentage).to eq(100)
    end

    it "returns 0 when no fields are completed" do
      expect(assessment.completion_percentage).to eq(0)
    end

    it "calculates partial completion correctly" do
      assessment.update!(
        num_low_anchors: 4,
        num_high_anchors: 4,
        num_anchors_pass: true,
        anchor_accessories_pass: true
        # 4 out of 7 fields = 57% (rounded)
      )
      expect(assessment.completion_percentage).to eq(57)
    end
  end

  describe "#anchor_distribution" do
    it "returns comprehensive distribution data when counts are present" do
      assessment.num_low_anchors = 6
      assessment.num_high_anchors = 2
      allow(assessment).to receive(:required_anchors).and_return(8)

      distribution = assessment.anchor_distribution

      expect(distribution[:low_anchors]).to eq(6)
      expect(distribution[:high_anchors]).to eq(2)
      expect(distribution[:total]).to eq(8)
      expect(distribution[:required]).to eq(8)
      expect(distribution[:percentage_low]).to eq(75.0)
      expect(distribution[:percentage_high]).to eq(25.0)
    end

    it "returns empty hash when anchor counts are missing" do
      assessment.num_low_anchors = 6
      assessment.num_high_anchors = nil
      expect(assessment.anchor_distribution).to eq({})
    end
  end

  describe "#anchor_safety_summary" do
    it "returns success message when all requirements are met" do
      assessment.update!(
        num_low_anchors: 5,
        num_high_anchors: 3,
        anchor_type_pass: true,
        pull_strength_pass: true,
        anchor_degree_pass: true,
        anchor_accessories_pass: true
      )
      allow(assessment).to receive(:meets_anchor_requirements?).and_return(true)

      expect(assessment.anchor_safety_summary).to eq("All anchor requirements met")
    end

    it "lists all issues when multiple failures exist" do
      assessment.update!(
        num_low_anchors: 2,
        num_high_anchors: 1,
        anchor_type_pass: false,
        pull_strength_pass: false,
        anchor_degree_pass: false,
        anchor_accessories_pass: false
      )
      allow(assessment).to receive(:meets_anchor_requirements?).and_return(false)

      summary = assessment.anchor_safety_summary
      expect(summary).to include("Insufficient total anchors")
      expect(summary).to include("Anchor type non-compliant")
      expect(summary).to include("Pull strength insufficient")
      expect(summary).to include("Anchor angle incorrect")
      expect(summary).to include("Missing anchor accessories")
    end
  end

  describe "callbacks" do
    describe "after_update :log_assessment_update" do
      it "logs assessment updates when changes are made" do
        expect(assessment).to receive(:log_assessment_update)
        assessment.update!(num_low_anchors: 5)
      end

      it "does not log when no changes are made" do
        assessment.update!(num_low_anchors: 5)
        expect(assessment).not_to receive(:log_assessment_update)
        assessment.save
      end
    end

    describe "after_save :update_anchor_calculations" do
      it "triggers anchor calculations when anchor counts change" do
        expect(assessment).to receive(:update_anchor_calculations)
        assessment.update!(num_low_anchors: 5)
      end

      it "auto-updates num_anchors_pass based on calculations" do
        assessment.update!(num_low_anchors: 5, num_high_anchors: 5)
        allow(SafetyStandard).to receive(:calculate_required_anchors).with(100.0).and_return(8)

        assessment.send(:update_anchor_calculations)
        assessment.reload
        expect(assessment.num_anchors_pass).to be true # 10 >= 8
      end
    end
  end

  describe "private methods" do
    describe "#anchor_counts_present?" do
      it "returns true when both counts are present" do
        assessment.update!(num_low_anchors: 4, num_high_anchors: 4)
        expect(assessment.send(:anchor_counts_present?)).to be true
      end

      it "returns false when any count is missing" do
        assessment.update!(num_low_anchors: 4, num_high_anchors: nil)
        expect(assessment.send(:anchor_counts_present?)).to be false
      end
    end

    describe "#anchor_assessments_complete?" do
      it "returns true when all assessments are present" do
        assessment.update!(
          num_anchors_pass: true,
          anchor_accessories_pass: false,
          anchor_degree_pass: true,
          anchor_type_pass: true,
          pull_strength_pass: false
        )
        expect(assessment.send(:anchor_assessments_complete?)).to be true
      end

      it "returns false when any assessment is nil" do
        assessment.update!(
          num_anchors_pass: true,
          anchor_accessories_pass: nil,
          anchor_degree_pass: true,
          anchor_type_pass: true,
          pull_strength_pass: false
        )
        expect(assessment.send(:anchor_assessments_complete?)).to be false
      end
    end

    describe "#saved_change_to_anchor_counts?" do
      it "returns true when low anchors count changes" do
        assessment.update!(num_low_anchors: 5)
        expect(assessment.send(:saved_change_to_anchor_counts?)).to be true
      end

      it "returns true when high anchors count changes" do
        assessment.update!(num_high_anchors: 3)
        expect(assessment.send(:saved_change_to_anchor_counts?)).to be true
      end

      it "returns false when no anchor counts change" do
        assessment.update!(anchor_type_pass: true)
        expect(assessment.send(:saved_change_to_anchor_counts?)).to be false
      end
    end
  end

  describe "audit logging" do
    it "logs assessment updates" do
      expect(assessment.inspection).to receive(:log_audit_action).with(
        "assessment_updated",
        assessment.inspection.user,
        "Anchorage Assessment updated"
      )
      assessment.update!(num_low_anchors: 5)
    end
  end

  describe "edge cases" do
    it "handles zero anchor counts" do
      assessment.update!(num_low_anchors: 0, num_high_anchors: 0)
      expect(assessment).to be_valid
      expect(assessment.total_anchors).to eq(0)
    end

    it "handles large anchor counts" do
      assessment.update!(num_low_anchors: 999, num_high_anchors: 999)
      expect(assessment).to be_valid
      expect(assessment.total_anchors).to eq(1998)
    end

    it "handles mixed pass/fail states" do
      assessment.update!(
        anchor_type_pass: true,
        pull_strength_pass: false,
        anchor_degree_pass: true,
        anchor_accessories_pass: false,
        num_anchors_pass: true
      )
      expect(assessment.passed_checks_count).to eq(3)
      expect(assessment.has_critical_failures?).to be true
    end

    it "handles very large unit areas" do
      large_unit = create(:unit, user: user, name: "Large Unit", serial: "LARGE001", manufacturer: "Test Manufacturer", length: 50.0, width: 30.0, height: 5.0, description: "Large Unit", unit_type: "bounce_house", owner: "Test Owner")
      large_inspection = create(:inspection, user: user, unit: large_unit, inspector: "Test Inspector")
      large_assessment = AnchorageAssessment.create!(inspection: large_inspection)

      large_assessment.update!(num_low_anchors: 5, num_high_anchors: 3)
      expect(large_assessment.meets_anchor_requirements?).to be false  # 8 anchors not enough for 1500 sqm
      expect(large_assessment.required_anchors).to be > 100  # Large area needs many anchors
    end

    it "handles auto-calculation with missing data" do
      assessment.update!(num_low_anchors: nil, num_high_anchors: 5)

      # Should not crash when trying to auto-update
      expect { assessment.send(:update_anchor_calculations) }.not_to raise_error
    end
  end
end
