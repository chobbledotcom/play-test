require "rails_helper"

RSpec.feature "Inspection Auto-save without JavaScript", type: :feature do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }

  before do
    sign_in(user)
  end

  scenario "displays auto-save status elements on assessment forms" do
    inspection.create_user_height_assessment!
    visit edit_inspection_path(inspection, tab: "user_height")

    # Check that auto-save status is present (hidden by default)
    expect(page).to have_css("[data-autosave-status]", visible: :all)

    # Check form has auto-save data attributes
    expect(page).to have_css('form[data-autosave="true"]')

    # Verify form is configured for Turbo
    form = find('form[data-autosave="true"]', match: :first)
    expect(form["data-turbo-stream"]).to eq("true")
  end

  scenario "displays progress indicators with turbo frames" do
    visit edit_inspection_path(inspection)

    # Check for turbo frame that would update progress
    expect(page).to have_css("turbo-frame#inspection_progress_#{inspection.id}")

    # Check for completion issues turbo frame
    expect(page).to have_css("turbo-frame#completion_issues_#{inspection.id}")
  end

  scenario "all assessment forms are configured for auto-save" do
    # Create all assessments
    inspection.create_user_height_assessment!
    inspection.create_slide_assessment! if inspection.has_slide?
    inspection.create_structure_assessment!
    inspection.create_materials_assessment!
    inspection.create_anchorage_assessment!
    inspection.create_fan_assessment!
    inspection.create_enclosed_assessment! if inspection.is_totally_enclosed?

    # Check each available tab
    inspection_tabs = %w[user_height structure materials anchorage fan]
    inspection_tabs << "slide" if inspection.has_slide?
    inspection_tabs << "enclosed" if inspection.is_totally_enclosed?

    inspection_tabs.each do |tab|
      visit edit_inspection_path(inspection, tab: tab)

      # Each form should have auto-save attributes
      expect(page).to have_css("form[data-autosave='true']")
      expect(page).to have_css("form[data-turbo-stream='true']")

      # Auto-save status should be included
      within("form[data-autosave='true']") do
        expect(page).to have_css("[data-autosave-status]", visible: :all)
      end
    end
  end

  scenario "form submission works without JavaScript" do
    inspection.create_user_height_assessment!
    visit edit_inspection_path(inspection, tab: "user_height")

    # Fill in a field using the label text
    fill_in I18n.t("inspections.assessments.user_height.fields.containing_wall_height"), with: "2.5"

    # Submit form (simulating what would happen with auto-save disabled)
    click_button I18n.t("inspections.buttons.save_assessment")

    # Should redirect to inspection show page (standard Rails behavior without Turbo)
    expect(page).to have_current_path(inspection_path(inspection))
    expect(page).to have_content(I18n.t("inspections.messages.updated"))

    # Value should be saved
    inspection.reload
    expect(inspection.user_height_assessment.containing_wall_height).to eq(2.5)
  end

  scenario "displays all required locale keys for auto-save" do
    inspection.create_user_height_assessment!
    visit edit_inspection_path(inspection, tab: "user_height")

    # Check that all auto-save locale keys are present in the HTML
    autosave_element = find("[data-autosave-status]", visible: :all)

    expect(autosave_element.text(:all)).to include(I18n.t("autosave.saving"))
    expect(autosave_element.text(:all)).to include(I18n.t("autosave.saved"))
    expect(autosave_element.text(:all)).to include(I18n.t("autosave.error"))
  end

  scenario "progress percentage updates via turbo frame" do
    # Create some assessments with proper attributes
    inspection.create_user_height_assessment!(containing_wall_height: 2.0)
    inspection.create_structure_assessment!(
      seam_integrity_pass: true,
      lock_stitch_pass: true,
      air_loss_pass: true,
      straight_walls_pass: true,
      sharp_edges_pass: true,
      unit_stable_pass: true,
      stitch_length: 5,
      unit_pressure_value: 1.5,
      blower_tube_length: 1.5
    )

    visit edit_inspection_path(inspection)

    # Progress should be displayed
    within("turbo-frame#inspection_progress_#{inspection.id}") do
      expect(page).to have_css(".value")
      # With 2 complete assessments out of 6 standard tabs (excluding general)
      expect(page).to have_text(/\d+%/)
    end
  end

  scenario "shows slide form only for inspections with slides" do
    # Inspection without slide
    expect(inspection.has_slide?).to be false
    visit edit_inspection_path(inspection, tab: "general")

    # Should not see slide tab
    expect(page).not_to have_link(I18n.t("inspections.tabs.slide"))

    # Update to have slide
    inspection.update!(has_slide: true)
    visit edit_inspection_path(inspection, tab: "general")

    # Should now see slide tab
    expect(page).to have_link(I18n.t("inspections.tabs.slide"))
  end

  scenario "shows enclosed form only for totally enclosed inspections" do
    # Inspection without being totally enclosed
    expect(inspection.is_totally_enclosed?).to be false
    visit edit_inspection_path(inspection, tab: "general")

    # Should not see enclosed tab
    expect(page).not_to have_link(I18n.t("inspections.tabs.enclosed"))

    # Update to be totally enclosed
    inspection.update!(is_totally_enclosed: true)
    visit edit_inspection_path(inspection, tab: "general")

    # Should now see enclosed tab
    expect(page).to have_link(I18n.t("inspections.tabs.enclosed"))
  end
end
