require "rails_helper"

# Build all tab names from ASSESSMENT_TYPES plus the general inspection tab
ALL_TAB_NAMES = ["inspections", ""] +
  Inspection::ASSESSMENT_TYPES.keys.map { |k| k.to_s.sub(/_assessment$/, "") }

RSpec.feature "Assessment Forms", type: :feature do
  let(:admin_user) { create(:user, :without_company, email: "admin@testcompany.com") }
  let(:inspection_company) { create(:inspector_company, name: "Test Company") }
  let(:user) { create(:user, inspection_company: inspection_company) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, unit: unit, user: user) }
  let(:slide_unit) { create(:unit, user: user) }
  let(:slide_inspection) { create(:inspection, unit: slide_unit, user: user, has_slide: true) }
  let(:enclosed_inspection) { create(:inspection, :totally_enclosed, user: user) }

  before do
    sign_in(user)
  end

  describe "form rendering" do
    ALL_TAB_NAMES.each do |tab_name|
      # Skip empty string tab (same as "inspections")
      next if tab_name.empty?

      scenario "renders #{tab_name} form without errors" do
        # Use slide_inspection for all tests since it has both slide and regular assessments
        # Use enclosed_inspection for enclosed tab
        inspection_to_use = (tab_name == "enclosed") ? enclosed_inspection : slide_inspection

        visit edit_inspection_path(inspection_to_use, tab: tab_name)
        expect_assessment_form_rendered(tab_name)
      end
    end

    scenario "shows conditional tabs only when appropriate" do
      # Verify enclosed_inspection is actually totally enclosed
      expect(enclosed_inspection.is_totally_enclosed).to be true

      # Enclosed tab only for totally enclosed units
      visit edit_inspection_path(enclosed_inspection)
      expect_assessment_tab("enclosed")

      visit edit_inspection_path(inspection)
      expect_no_assessment_tab("enclosed")

      # Verify slide_inspection actually has a slide
      expect(slide_inspection.has_slide).to be true

      # Slide tab only for units with slides
      visit edit_inspection_path(slide_inspection)
      expect_assessment_tab("slide")

      visit edit_inspection_path(inspection)
      expect_no_assessment_tab("slide")
    end
  end

  describe "Assessment Navigation" do
    it "allows switching between different assessment tabs" do
      # Define tabs to test
      tabs_to_test = %w[user_height structure materials anchorage fan inspections]

      # Add slide tab if inspection has slide
      if slide_inspection.has_slide
        tabs_to_test << "slide"
      end

      # Ensure inspection has a unit (required for some tabs)
      expect(inspection.unit).to be_present

      # Start with general tab
      visit edit_inspection_path(inspection)

      # Test each tab navigation
      tabs_to_test.each do |tab_name|
        # For slide tab, we need to use the slide inspection
        if tab_name == "slide"
          visit edit_inspection_path(slide_inspection, tab: "slide")
        else
          # Check if we're already on this tab
          current_tab_matches = current_url.include?("tab=#{tab_name}")

          # Skip clicking if we're already on this tab
          unless current_tab_matches
            click_assessment_tab(tab_name)
          end
        end

        expect(current_url).to include("tab=#{tab_name}")
        expect_form_matches_i18n("forms.#{tab_name}")
        expect(page).not_to have_content("translation missing")
      end

      if enclosed_inspection.is_totally_enclosed
        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")
        expect(current_url).to include("tab=enclosed")
        expect_form_matches_i18n("forms.enclosed")
        expect(page).not_to have_content("translation missing")
      end
    end

    context "for totally enclosed units" do
      it "includes enclosed tab in navigation" do
        visit edit_inspection_path(enclosed_inspection)

        # Should have enclosed tab
        expect_assessment_tab("enclosed")

        # Can navigate to enclosed assessment
        click_assessment_tab("enclosed")
        expect_form_matches_i18n("forms.enclosed")
      end
    end

    it "maintains correct tab state in URL" do
      visit edit_inspection_path(inspection, tab: "structure")
      expect(current_url).to include("tab=structure")

      click_assessment_tab("materials")
      expect(current_url).to include("tab=materials")
    end
  end

  describe "Assessment Summary Display" do
    it "shows assessment summary for structure assessment with data" do
      # Visit to create the assessment
      visit edit_inspection_path(inspection)

      # Update the auto-created assessment
      inspection.structure_assessment.update!(
        seam_integrity_pass: true,
        uses_lock_stitching_pass: true,
        air_loss_pass: false,
        straight_walls_pass: true,
        sharp_edges_pass: true,
        unit_stable_pass: true,
        stitch_length: 10.0,
        unit_pressure: 500.0
      )

      visit edit_inspection_path(inspection, tab: "structure")

      expect(page).to have_css(".assessment-status")
      # Structure assessment summary is displayed with critical failure noted
      expect(page).to have_content("Critical Failures")
      expect(page).to have_content("Air loss pass")
    end

    it "shows material compliance summary for materials assessment with data" do
      # Visit to create the assessment
      visit edit_inspection_path(inspection)

      # Update the auto-created assessment
      inspection.materials_assessment.update!(
        ropes: 25.0,
        ropes_pass: true,
        clamber_netting_pass: true,
        retention_netting_pass: false,
        zips_pass: true,
        windows_pass: true,
        artwork_pass: true,
        thread_pass: true,
        fabric_strength_pass: true
      )

      visit edit_inspection_path(inspection, tab: "materials")

      # Materials assessment status is displayed
      expect(page).to have_css(".assessment-status")
      expect(page).to have_content("Fields completed:")
    end

    it "shows anchorage assessment summary for anchorage assessment with data" do
      # Visit to create the assessment
      visit edit_inspection_path(inspection)

      # Update the auto-created assessment
      inspection.anchorage_assessment.update!(
        num_low_anchors: 4,
        num_high_anchors: 2,
        anchor_type_pass: true,
        pull_strength_pass: false
      )

      visit edit_inspection_path(inspection, tab: "anchorage")

      # Anchorage assessment status is displayed
      expect(page).to have_css(".assessment-status")
      expect(page).to have_content("Fields completed:")
    end

    context "for totally enclosed units" do
      it "shows enclosed assessment summary for enclosed assessment with data" do
        # Visit to create the assessment
        visit edit_inspection_path(enclosed_inspection)

        # Update the auto-created assessment
        enclosed_inspection.enclosed_assessment.update!(
          exit_number: 2,
          exit_number_pass: true,
          exit_sign_always_visible_pass: false
        )

        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")

        # Enclosed assessment status is displayed
        expect(page).to have_css(".assessment-status")
        expect(page).to have_content("Fields completed:")
      end
    end
  end

  describe "Form Functionality" do
    it "saves slide assessment data when form is submitted" do
      visit edit_inspection_path(slide_inspection, tab: "slide")

      # Use field name instead of label text since label doesn't have 'for' attribute
      fill_in "assessments_slide_assessment[slide_platform_height]", with: "2.5"

      click_button I18n.t("forms.slide.submit")

      expect(page).to have_content(I18n.t("inspections.messages.updated"))
      slide_inspection.reload
      expect(slide_inspection.slide_assessment.slide_platform_height).to eq(2.5)
    end
  end

  describe "Assessment Status Display" do
    it "shows assessment status when assessments are persisted" do
      # Ensure assessments are created
      expect(slide_inspection.slide_assessment).to be_present
      expect(slide_inspection.user_height_assessment).to be_present

      # Update the assessments that were automatically created
      slide_inspection.slide_assessment.update!(slide_platform_height: 2.0)
      slide_inspection.user_height_assessment.update!(containing_wall_height: 1.5)
      slide_inspection.structure_assessment.update!(seam_integrity_pass: true, stitch_length: 10.0)
      slide_inspection.materials_assessment.update!(fabric_strength_pass: true)
      slide_inspection.anchorage_assessment.update!(num_low_anchors: 4)
      slide_inspection.fan_assessment.update!(blower_serial: "FAN123")

      visit edit_inspection_path(slide_inspection, tab: "slide")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(slide_inspection, tab: "user_height")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(slide_inspection, tab: "structure")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(slide_inspection, tab: "materials")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(slide_inspection, tab: "anchorage")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(slide_inspection, tab: "fan")
      expect(page).to have_css(".assessment-status")
    end

    context "for totally enclosed units" do
      it "shows assessment status for enclosed assessments" do
        # Visit the edit page to create the assessment
        visit edit_inspection_path(enclosed_inspection)

        # Update the assessment that was automatically created
        enclosed_inspection.enclosed_assessment.update!(exit_number: 2)

        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")
        expect(page).to have_css(".assessment-status")
      end
    end

    it "shows assessment status even for empty assessments" do
      # Create a fresh inspection with a slide
      fresh_inspection = create(:inspection, user: user, has_slide: true)

      # Verify assessments exist but are empty (no data filled in)
      expect(fresh_inspection.slide_assessment).to be_present
      expect(fresh_inspection.slide_assessment.slide_platform_height).to be_nil

      visit edit_inspection_path(fresh_inspection, tab: "slide")
      # Assessment status shows even when empty since assessments are auto-created
      expect(page).to have_css(".assessment-status")
      # Should show incomplete fields for empty assessment
      expect(page).to have_content("incomplete fields")
    end
  end

  private

  def expect_assessment_form_rendered(tab_name)
    # The form header is rendered by form_context
    expect(page).to have_content(I18n.t("forms.#{tab_name}.header"))
    expect(page).not_to have_content("translation missing")
    expect(page).to have_button(I18n.t("forms.#{tab_name}.submit"))
  end
end
