require "rails_helper"

RSpec.describe Assessments::AnchorageAssessment, type: :model do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }
  let(:assessment) { inspection.anchorage_assessment }

  # Use shared examples for common behaviors
  it_behaves_like "an assessment model"
  it_behaves_like "has safety check methods"
  it_behaves_like "delegates to SafetyStandard", [:calculate_required_anchors]

  describe "validations" do
    context "anchor counts" do
      %w[num_low_anchors num_high_anchors].each do |field|
        include_examples "validates non-negative integer field", field
      end
    end

    context "pass/fail assessments" do
      %w[num_anchors_pass anchor_accessories_pass anchor_degree_pass
        anchor_type_pass pull_strength_pass].each do |field|
        include_examples "validates boolean field", field
      end
    end

    context "comment fields" do
      %w[num_anchors_comment anchor_accessories_comment anchor_degree_comment
        anchor_type_comment pull_strength_comment].each do |field|
        include_examples "validates comment field", field
      end
    end
  end

  describe "#complete?" do
    it "returns true when all requirements are met" do
      assessment.update!(
        num_low_anchors: 4,
        num_high_anchors: 4,
        num_anchors_pass: true,
        num_low_anchors_pass: true,
        num_high_anchors_pass: true,
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
        assessment.inspection.width = 10.0
        assessment.inspection.height = 10.0
        assessment.num_low_anchors = 4
        assessment.num_high_anchors = 4

        expect(SafetyStandard).to receive(:calculate_required_anchors).with(100.0).and_return(6)
        expect(assessment.meets_anchor_requirements?).to be true # 8 >= 6
      end

      it "returns false when anchors are insufficient" do
        assessment.inspection.width = 10.0
        assessment.inspection.height = 10.0
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
      inspection.update!(width: 10.0, height: 10.0) # Creates area of 100.0
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
    describe "after_save :update_anchor_calculations" do
      it "triggers anchor calculations when anchor counts change" do
        expect(assessment).to receive(:update_anchor_calculations)
        assessment.update!(num_low_anchors: 5)
      end

      it "auto-updates num_anchors_pass based on calculations" do
        inspection.update!(width: 10.0, height: 10.0) # Creates area of 100.0
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
      large_unit = create(:unit, user: user, name: "Large Unit", serial: "LARGE001", manufacturer: "Test Manufacturer", description: "Large Unit", owner: "Test Owner")
      large_inspection = create(:inspection, user: user, unit: large_unit, width: 50.0, length: 30.0, height: 5.0)
      large_assessment = large_inspection.anchorage_assessment

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
