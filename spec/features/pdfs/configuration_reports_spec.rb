# typed: false
# frozen_string_literal: true

require "rails_helper"
require "pdf/inspector"

RSpec.feature "Configuration-aware inspection reports", type: :feature do
  let(:user) { create(:user) }

  background do
    sign_in user
  end

  scenario "JSON and PDF include pillow site, measurements and explicit N/A" do
    unit = create(:unit, user: user, unit_type: :bouncing_pillow,
      has_slide: false, is_totally_enclosed: false, has_fencing: false,
      has_blower: false)
    inspection = create(:inspection, user: user, unit: unit,
      has_slide: false, is_totally_enclosed: false,
      inspection_location: "North meadow installation")
    inspection.bouncing_pillow_assessment.update!(
      internal_pressure: 2.3, internal_pressure_pass: "pass",
      internal_pressure_comment: "Measured after inflation",
      slope: 3.2, slope_pass: "pass", number_of_users: 18,
      number_of_users_pass: "pass", grounding_pass: "na",
      grounding_comment: "Explicit inspector judgement",
      fencing_height: 9.9, fencing_height_pass: "fail",
      fencing_height_comment: "Inapplicable fence comment")

    visit inspection_path(inspection, format: :json)
    report = JSON.parse(page.body)
    pillow = report.fetch("assessments").fetch("bouncing_pillow_assessment")
    expect(report.fetch("inspection_location"))
      .to eq("North meadow installation")
    expect(report.fetch("has_fencing")).to be false
    expect(report).not_to have_key("checklist_revision")
    expect(pillow.fetch("internal_pressure").to_f).to eq(2.3)
    expect(pillow.fetch("number_of_users")).to eq(18)
    expect(pillow.fetch("grounding_pass")).to eq("na")
    expect(pillow.fetch("grounding_comment"))
      .to eq("Explicit inspector judgement")
    expect(pillow.keys).not_to include("fencing_height",
      "fencing_height_pass", "fencing_height_comment")
    expect(report.fetch("assessments")).not_to have_key("fan_assessment")

    visit inspection_path(inspection, format: :pdf)
    text = PDF::Inspector::Text.analyze(page.source).strings.join(" ")
    expect(text).to include("North meadow installation",
      "Measured after inflation", "Explicit inspector judgement",
      I18n.t("shared.na_pdf"), "2.3", "18")
    %i[inflatable site impact_area].each do |section|
      key = "forms.bouncing_pillow.sections.#{section}"
      expect(text).to include(I18n.t(key))
    end
    expect(text).not_to include("Inapplicable fence comment")

    visit edit_inspection_path(inspection, tab: "results")
    expect(page).to have_content("Explicit inspector judgement")
    expect(page).not_to have_content("Inapplicable fence comment")
  end

  scenario "legacy exports preserve boolean and enum outcome interpretation" do
    inspection = create(:inspection, user: user)
    inspection.materials_assessment.update!(thread_pass: "fail",
      ropes: 5, ropes_pass: "pass")
    inspection.update_columns(checklist_revision: nil)
    inspection.reload

    visit inspection_path(inspection, format: :json)
    report = JSON.parse(page.body)
    materials = report.fetch("assessments").fetch("materials_assessment")
    expect(materials.fetch("thread_pass")).to be false
    expect(materials.fetch("ropes_pass")).to eq("pass")
    expect(report).not_to have_key("has_fencing")
    expect(report.fetch("assessments"))
      .not_to have_key("bouncing_pillow_assessment")
    expect(inspection.reload.checklist_revision).to be_nil
  end

  scenario "reading legacy reports never creates missing assessment rows" do
    inspection = create(:inspection, user: user)
    inspection.materials_assessment.destroy!
    inspection.update_columns(checklist_revision: nil)
    inspection.reload
    classes = inspection.assessment_types.values
    counts = classes.to_h { |klass| [klass, klass.count] }

    visit inspection_path(inspection, format: :json)
    expect(JSON.parse(page.body)).not_to have_key("checklist_revision")
    visit inspection_path(inspection, format: :pdf)
    expect(page.source).to start_with("%PDF")

    expect(classes.to_h { |klass| [klass, klass.count] }).to eq(counts)
    expect(inspection.reload.checklist_revision).to be_nil
  end

  scenario "historical inspection details keep their own dimensions and site" do
    unit = create(:unit, user: user, unit_type: :bouncing_pillow,
      has_slide: false, is_totally_enclosed: false, has_blower: false)
    earlier = create(:inspection, user: user, unit: unit,
      has_slide: false, is_totally_enclosed: false,
      width: 3.21, length: 4.32, height: 2.34,
      inspection_location: "Original inspection site")
    create(:inspection, :completed, user: user, unit: unit,
      has_slide: false, is_totally_enclosed: false,
      width: 8.76, length: 9.87, height: 7.65,
      inspection_date: Date.current + 1.day,
      inspection_location: "Replacement inspection site")

    visit inspection_path(earlier)
    expect(page).to have_content("3.21")
    expect(page).to have_content("Original inspection site")
    expect(page).not_to have_content("Replacement inspection site")
    expect(page).not_to have_content("8.76")
  end

  scenario "legacy bungee exports keep the historical harness requirement" do
    unit = create(:unit, user: user, unit_type: :bungee_run,
      has_slide: false, is_totally_enclosed: false)
    inspection = create(:inspection, user: user, unit: unit,
      has_slide: false, is_totally_enclosed: false)
    inspection.bungee_assessment.update!(pull_strength: 1234,
      pull_strength_pass: "pass", maximum_users: 7)
    inspection.update_columns(checklist_revision: nil)

    visit inspection_path(inspection, format: :json)
    bungee = JSON.parse(page.body).fetch("assessments")
      .fetch("bungee_assessment")
    expect(bungee.fetch("pull_strength_pass")).to be true
    expect(bungee).not_to have_key("pull_strength")
    expect(bungee).not_to have_key("maximum_users")

    visit inspection_path(inspection, format: :pdf)
    text = PDF::Inspector::Text.analyze(page.source).strings.join(" ")
      .gsub(/\s+/, " ")
    legacy_label = I18n.t("forms.bungee.legacy_fields.pull_strength")
    current_label = I18n.t("forms.bungee.fields.pull_strength")
    expect(text).to include(legacy_label.gsub(/\s+/, " "))
    expect(text).not_to include(current_label.gsub(/\s+/, " "))
    expect(text).not_to include("1234")
    expect(text).not_to include(I18n.t("forms.bungee.fields.maximum_users"))
  end

  {
    inflatable_ball_pool: :ball_pool,
    bungee_run: :bungee,
    catch_bed: :catch_bed,
    inflatable_game: :inflatable_game
  }.each do |unit_type, assessment_type|
    scenario "current #{unit_type} reports include the actual maximum users" do
      unit = create(:unit, user: user, unit_type: unit_type,
        has_slide: false, is_totally_enclosed: false)
      inspection = create(:inspection, user: user, unit: unit,
        has_slide: false, is_totally_enclosed: false)
      assessment_key = :"#{assessment_type}_assessment"
      inspection.public_send(assessment_key).update!(maximum_users: 7)

      visit inspection_path(inspection, format: :json)
      data = JSON.parse(page.body).fetch("assessments")
        .fetch(assessment_key.to_s)
      expect(data.fetch("maximum_users")).to eq(7)

      visit inspection_path(inspection, format: :pdf)
      text = PDF::Inspector::Text.analyze(page.source).strings.join(" ")
        .gsub(/\s+/, " ")
      label = I18n.t("forms.#{assessment_type}.fields.maximum_users")
      escaped_label = Regexp.escape(label)
      expect(text).to match(/#{escaped_label}\s*:\s*7\b/)
    end
  end
end
