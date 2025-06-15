require "rails_helper"

# Build all tab names from ASSESSMENT_TYPES plus the general inspection tab
ALL_TAB_NAMES = ["inspection", ""] +
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
      tabs_to_test = %w[user_height structure materials anchorage fan inspection]

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
