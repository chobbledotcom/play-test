# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Recorded user limits and advisory guidance", type: :feature do
  include InspectionTestHelpers

  let(:user) { create(:user) }

  background { sign_in(user) }

  scenario "saves fractional slide runout measurements" do
    unit = create(:unit, user: user, unit_type: :bouncy_castle,
      has_slide: true)
    inspection = create(:inspection, user: user, unit: unit)
    visit edit_inspection_path(inspection, tab: "slide")

    fill_in_form :slide, :runout, 2.75
    choose_pass_fail(get_field_label(:slide, :runout_pass), "pass")
    submit_form :slide
    expect_updated_message

    expect(inspection.slide_assessment.reload.runout).to eq(BigDecimal("2.75"))
    expect(inspection.slide_assessment.runout_pass).to eq("pass")
  end

  scenario "an unsafe harness test is saved with a manual outcome and limits" do
    unit = create(:unit, user: user, unit_type: :bungee_run)
    inspection = create(:inspection, user: user, unit: unit)
    visit edit_inspection_path(inspection, tab: "bungee")

    fill_in_form :bungee, :maximum_users, 7
    fill_in_form :bungee, :marking_max_mass, 125
    fill_in_form :bungee, :marking_min_height, 1.1
    fill_in_form :bungee, :pull_strength, 1200
    choose_pass_fail(get_field_label(:bungee, :pull_strength_pass), "fail")
    submit_form :bungee

    assessment = inspection.bungee_assessment.reload
    expect(assessment.maximum_users).to eq(7)
    expect(assessment.marking_max_mass).to eq(125)
    expect(assessment.marking_min_height).to eq(BigDecimal("1.1"))
    expect(assessment.pull_strength).to eq(1200)
    expect(assessment.pull_strength_pass).to eq("fail")
    visit edit_inspection_path(inspection, tab: "bungee")
    guidance_title = I18n.t("assessment_guidance.title")
    within("aside[aria-label='#{guidance_title}']") do
      expect(page).to have_content(I18n.t("assessment_guidance.rules.harness_pull"))
      expect(page).to have_content(I18n.t("assessment_guidance.status.outside"))
    end
  end

  {
    inflatable_ball_pool: ["ball_pool", :max_height_markings, 1.2],
    play_zone: ["play_zone", :height_marking, 1.2],
    inflatable_game: ["inflatable_game", :max_user_mass, 125]
  }.each do |type, (tab, limit_field, limit)|
    scenario "records actual age and user limits for #{type}" do
      components = (type == :inflatable_game) ? {has_inflatable_bed: true} : {}
      unit = create(:unit, user: user, unit_type: type, **components)
      inspection = create(:inspection, user: user, unit: unit)
      visit edit_inspection_path(inspection, tab: tab)

      fill_in_form tab, :maximum_users, 7 unless type == :play_zone
      fill_in_form tab, :minimum_age, 2
      fill_in_form tab, :maximum_age, 8
      fill_in_form tab, limit_field, limit
      submit_form tab.to_sym

      assessment = inspection.public_send("#{tab}_assessment").reload
      expect(assessment.maximum_users).to eq(7) unless type == :play_zone
      expect(assessment.minimum_age).to eq(2)
      expect(assessment.maximum_age).to eq(8)
      expect(assessment.public_send(limit_field)).to eq(limit)
      visit edit_inspection_path(inspection, tab: tab)
      minimum_age = find_field(
        I18n.t("forms.#{tab}.fields.minimum_age")
      ).value
      expect(BigDecimal(minimum_age)).to eq(2)
    end
  end

  scenario "records catch-bed mass while allowing an unsafe bed measurement" do
    unit = create(:unit, user: user, unit_type: :catch_bed)
    inspection = create(:inspection, user: user, unit: unit)
    visit edit_inspection_path(inspection, tab: "catch_bed")

    fill_in_form :catch_bed, :maximum_users, 7
    fill_in_form :catch_bed, :max_user_mass_marking, 125
    fill_in_form :catch_bed, :bed_height, 399
    choose_pass_fail(get_field_label(:catch_bed, :bed_height_pass), "fail")
    submit_form :catch_bed

    assessment = inspection.catch_bed_assessment.reload
    expect(assessment.maximum_users).to eq(7)
    expect(assessment.max_user_mass_marking).to eq(125)
    expect(assessment.bed_height).to eq(399)
    expect(assessment.bed_height_pass).to eq("fail")
    visit edit_inspection_path(inspection, tab: "catch_bed")
    expect(page).to have_content(I18n.t("assessment_guidance.rules.catch_bed_height"))
  end

  scenario "bungee anchorage offers only the formula when no area is supplied" do
    unit = create(:unit, user: user, unit_type: :bungee_run)
    inspection = create(:inspection, user: user, unit: unit)
    values = attributes_for(:anchorage_assessment, :complete)
      .merge(bungee_side_area: nil)
    inspection.anchorage_assessment.update!(values)
    visit edit_inspection_path(inspection, tab: "anchorage")

    expect(page).to have_content(I18n.t("assessment_guidance.bungee_anchors.source"))
    expect(page).to have_content(I18n.t("assessment_guidance.bungee_anchors.missing"))
    expect(find("input[name$='[bungee_side_area]']")[:required]).to be_nil
    submit_form :anchorage
    expect(inspection.anchorage_assessment.reload.complete?).to be true
    expect(inspection.anchorage_assessment.required_anchors).to be_nil
  end

  scenario "a supplied bungee area with missing counts is not a failure" do
    unit = create(:unit, user: user, unit_type: :bungee_run)
    inspection = create(:inspection, user: user, unit: unit)
    visit edit_inspection_path(inspection, tab: "anchorage")

    fill_in_form :anchorage, :bungee_side_area, 10
    submit_form :anchorage
    visit edit_inspection_path(inspection, tab: "anchorage")

    expect(page).to have_content(
      I18n.t("assessment_guidance.bungee_anchors.missing_counts")
    )
    expect(page).not_to have_content(
      I18n.t("assessment_guidance.status.outside")
    )
  end

  scenario "compares bungee totals with two rounded side requirements" do
    unit = create(:unit, user: user, unit_type: :bungee_run)
    inspection = create(:inspection, user: user, unit: unit)
    visit edit_inspection_path(inspection, tab: "anchorage")

    fill_in_form :anchorage, :bungee_side_area, 10
    fill_in_form :anchorage, :num_low_anchors, 2
    fill_in_form :anchorage, :num_high_anchors, 1
    submit_form :anchorage

    visit edit_inspection_path(inspection, tab: "anchorage")
    expect(page).to have_content(I18n.t("assessment_guidance.bungee_anchors.result",
      area: "10", per_side: 2, total: 4))
    expect(page).to have_content(I18n.t("assessment_guidance.bungee_anchors.comparison",
      actual: 3, status: I18n.t("assessment_guidance.status.outside")))
  end

  scenario "play-zone access geometry does not overwrite slide geometry" do
    unit = create(:unit, user: user, unit_type: :play_zone, has_slide: true)
    inspection = create(:inspection, user: user, unit: unit)
    inspection.slide_assessment.update!(slide_platform_height: 3)
    visit edit_inspection_path(inspection, tab: "play_zone")

    fill_in_form :play_zone, :slide_gradient, 65
    fill_in_form :play_zone, :slide_platform_height, 1.4
    choose_pass_fail(get_field_label(:play_zone, :slide_gradient_pass), "fail")
    submit_form :play_zone

    assessment = inspection.play_zone_assessment.reload
    expect(assessment.slide_gradient).to eq(65)
    expect(assessment.slide_gradient_pass).to eq("fail")
    expect(assessment.slide_platform_height).to eq(BigDecimal("1.4"))
    expect(inspection.slide_assessment.reload.slide_platform_height).to eq(3)
    visit edit_inspection_path(inspection, tab: "play_zone")
    expect(page).to have_content(I18n.t("assessment_guidance.rules.access_gradient"))
  end

  scenario "records the castle's actual maximum height and user counts" do
    unit = create(:unit, user: user, unit_type: :bouncy_castle)
    inspection = create(:inspection, user: user, unit: unit)
    visit edit_inspection_path(inspection, tab: "user_height")

    fill_in_form :user_height, :maximum_user_height, 1.2
    fill_in_form :user_height, :play_area_length, 4
    fill_in_form :user_height, :play_area_width, 4
    fill_in_form :user_height, :negative_adjustment, 1
    fill_in_form :user_height, :users_at_1000mm, 16
    submit_form :user_height

    assessment = inspection.user_height_assessment.reload
    expect(assessment.maximum_user_height).to eq(BigDecimal("1.2"))
    expect(assessment.users_at_1000mm).to eq(16)
    visit edit_inspection_path(inspection, tab: "user_height")
    expect(page).to have_content(I18n.t("assessment_guidance.rules.user_capacity",
      reference: 15))
    expect(page).to have_content(I18n.t("assessment_guidance.status.outside"))
  end

  scenario "an N/A harness test has no invented measurement or comparison" do
    unit = create(:unit, user: user, unit_type: :bungee_run)
    inspection = create(:inspection, user: user, unit: unit)
    visit edit_inspection_path(inspection, tab: "bungee")
    choose_pass_fail(get_field_label(:bungee, :pull_strength_pass), "na")
    submit_form :bungee

    expect(inspection.bungee_assessment.reload.pull_strength).to be_nil
    visit edit_inspection_path(inspection, tab: "bungee")
    expect(page).not_to have_content(I18n.t("assessment_guidance.rules.harness_pull"))
  end
end
