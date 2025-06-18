require "rails_helper"
require_relative "../../../db/seeds/seed_data"

RSpec.describe "form/_assessment_status.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  before do
    controller.params[:controller] = "inspections"
    controller.params[:tab] = "slide"
    assign(:inspection, inspection)
  end

  def render_assessment_status(assessment:, i18n_base: "forms.slide")
    render partial: "form/assessment_status",
      locals: {assessment: assessment, i18n_base: i18n_base}
  end

  def expect_safety_header_present
    expect(rendered).to include('<div class="assessment-status">')
    expect(rendered).to include(I18n.t("shared.assessment_completion"))
  end

  def expect_status_displayed(status_key, pass: true)
    expect(rendered).to include(pass ? "text-success" : "text-danger")
    expect(rendered).to include(I18n.t(pass ? "shared.pass" : "shared.fail"))
  end

  context "with slide assessment" do
    let(:slide_assessment) { inspection.slide_assessment }

    it "renders status for complete slide assessment" do
      slide_assessment.update!(SeedData.slide_fields(passed: true))

      render_assessment_status(assessment: slide_assessment, i18n_base: "forms.slide")

      expect_safety_header_present
      expect(rendered).to include(I18n.t("forms.slide.status.runout_requirement"))
      expect(rendered).to include(I18n.t("forms.slide.status.checks_passed"))
      expect(rendered).not_to include("incomplete-fields")
    end

    it "shows fail status for runout requirements" do
      slide_assessment.update!(
        SeedData.slide_fields(passed: false).merge(
          runout: 1.5,
          runout_pass: false
        )
      )

      render_assessment_status(assessment: slide_assessment, i18n_base: "forms.slide")

      expect(rendered).to include(I18n.t("forms.slide.status.runout_requirement"))
      expect_status_displayed("runout_requirement", pass: false)
    end
  end

  context "with user height assessment" do
    let(:user_height_assessment) { inspection.user_height_assessment }

    it "displays height requirement status as pass" do
      user_height_assessment.update!(
        SeedData.user_height_fields(passed: true).merge(
          containing_wall_height: 2.0,
          tallest_user_height: 1.5
        )
      )

      render_assessment_status(assessment: user_height_assessment, i18n_base: "forms.user_height")

      expect_safety_header_present
      expect(rendered).to include(I18n.t("forms.user_height.status.height_requirement"))
      expect_status_displayed("height_requirement", pass: true)
    end

    it "displays height requirement status as fail" do
      user_height_assessment.update!(
        SeedData.user_height_fields(passed: false).merge(
          containing_wall_height: 1.0,
          platform_height: 0.8,
          tallest_user_height: 1.9
        )
      )

      render_assessment_status(assessment: user_height_assessment, i18n_base: "forms.user_height")

      expect_status_displayed("height_requirement", pass: false)
    end
  end

  context "with materials assessment" do
    let(:materials_assessment) { inspection.materials_assessment }

    it "displays checks passed count" do
      materials_assessment.update!(SeedData.materials_fields(passed: true))

      render_assessment_status(assessment: materials_assessment, i18n_base: "forms.materials")

      expect(rendered).to include(I18n.t("forms.materials.status.checks_passed"))

      passed = materials_assessment.passed_checks_count
      total = materials_assessment.pass_columns_count
      expect(rendered.gsub(/\s+/, " ")).to include("#{passed} / #{total}")
    end
  end

  context "edge cases" do
    it "requires i18n_base" do
      expect {
        render partial: "form/assessment_status", locals: {assessment: inspection.slide_assessment}
      }.to raise_error(ActionView::Template::Error, /i18n_base is required/)
    end
  end

  context "HTML structure" do
    let(:slide_assessment) { inspection.slide_assessment }

    it "has proper semantic structure" do
      slide_assessment.update!(SeedData.slide_fields(passed: true))

      render_assessment_status(assessment: slide_assessment, i18n_base: "forms.slide")

      expect_safety_header_present
      expect(rendered).to include("<h4>")
      expect(rendered).to include("<p>")
      expect(rendered).to include("<strong>")
      expect(rendered).to include("<span")
    end
  end
end
