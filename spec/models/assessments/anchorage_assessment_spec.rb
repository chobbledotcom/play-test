# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Assessments::AnchorageAssessment, type: :model do
  let(:unit) { create(:unit, unit_type: :bungee_run) }
  let(:inspection) { create(:inspection, unit: unit, checklist_revision: 2) }
  let(:assessment) { inspection.anchorage_assessment }

  it "rounds each side up before doubling, not after doubling" do
    assessment.bungee_side_area = 10

    expect(assessment.required_anchors_per_side).to eq(2)
    expect(assessment.required_anchors).to eq(4)
  end

  it "does not round an exact per-side result up another whole anchor" do
    assessment.bungee_side_area = 320
    expect(assessment.required_anchors_per_side).to eq(57)

    assessment.bungee_side_area = BigDecimal("320.0001")
    expect(assessment.required_anchors_per_side).to eq(58)
    expect(assessment.required_anchors).to eq(116)
  end

  it "compares total low plus high anchors with both sides" do
    assessment.assign_attributes(bungee_side_area: 10,
      num_low_anchors: 2, num_high_anchors: 1)
    expect(assessment.meets_anchor_requirements?).to be false

    assessment.num_high_anchors = 2
    expect(assessment.meets_anchor_requirements?).to be true
  end

  it "does not mistake an unanswered side area or count for compliance" do
    assessment.assign_attributes(bungee_side_area: nil,
      num_low_anchors: 50, num_high_anchors: 50)
    expect(assessment.required_anchors_per_side).to be_nil
    expect(assessment.required_anchors).to be_nil
    expect(assessment.meets_anchor_requirements?).to be_nil

    assessment.assign_attributes(bungee_side_area: 10, num_high_anchors: nil)
    expect(assessment.meets_anchor_requirements?).to be_nil
  end

  it "allows completion without an undefined reference area" do
    values = attributes_for(:anchorage_assessment, :complete)
      .merge(bungee_side_area: nil)
    assessment.update!(values)

    expect(assessment.complete?).to be true
    expect(assessment.incomplete_fields).not_to include(:bungee_side_area)
    expect(assessment.required_anchors).to be_nil
  end

  it "preserves the existing calculation for untouched legacy bungees" do
    inspection.update_columns(checklist_revision: nil,
      length: 10, width: 4, height: 3)
    inspection.reload
    expected = EN14960.calculate_anchors(length: 10.0,
      width: 4.0, height: 3.0).value

    expect(assessment.required_anchors_per_side).to be_nil
    expect(assessment.required_anchors).to eq(expected)
  end

  it "preserves the castle calculation for current castle checklists" do
    castle = create(:inspection, checklist_revision: 2,
      length: 10, width: 4, height: 3)
    expected = EN14960.calculate_anchors(length: 10.0,
      width: 4.0, height: 3.0).value

    expect(castle.anchorage_assessment.required_anchors).to eq(expected)
  end
end
