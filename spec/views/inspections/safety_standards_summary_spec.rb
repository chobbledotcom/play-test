# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "inspections/_safety_standards_summary", type: :view do
  let(:unit) do
    create(:unit, unit_type: :bungee_run,
      has_slide: false, is_totally_enclosed: false)
  end
  let(:inspection) do
    create(:inspection, unit: unit, has_slide: false,
      is_totally_enclosed: false, indoor_only: false,
      width: nil, length: nil, height: nil)
  end

  it "shows source guidance without inventing a result for missing Area2" do
    render partial: "inspections/safety_standards_summary",
      locals: {inspection: inspection}

    expect(rendered).to include(
      I18n.t("assessment_guidance.bungee_anchors.source"),
      I18n.t("assessment_guidance.bungee_anchors.missing")
    )
    expect(rendered).not_to include(
      I18n.t("assessment_guidance.status.outside")
    )
    expect(rendered).not_to include('class="text-error"')
  end

  it "keeps missing anchor counts separate from an adverse comparison" do
    inspection.anchorage_assessment.update!(bungee_side_area: 10,
      num_low_anchors: nil, num_high_anchors: nil)

    render partial: "inspections/safety_standards_summary",
      locals: {inspection: inspection}

    expect(rendered).to include(
      I18n.t("assessment_guidance.bungee_anchors.missing_counts")
    )
    expect(rendered).not_to include(
      I18n.t("assessment_guidance.status.outside")
    )
    expect(rendered).not_to include('class="text-error"')
  end
end
