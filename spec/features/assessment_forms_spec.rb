require "rails_helper"

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
    %w[slide user_height structure materials anchorage fan].each do |tab_name|
      scenario "renders #{tab_name} assessment form without errors" do
        visit edit_inspection_path(inspection, tab: tab_name)

        expect_assessment_form_rendered(tab_name)
      end
    end

    context "for totally enclosed units" do
      scenario "renders enclosed assessment form without errors" do
        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")

        expect_assessment_form_rendered("enclosed")
      end

      scenario "shows enclosed tab only for totally enclosed units" do
        visit edit_inspection_path(enclosed_inspection)
        expect(page).to have_link(I18n.t("inspections.tabs.enclosed"))

        visit edit_inspection_path(inspection)
        expect(page).not_to have_link(I18n.t("inspections.tabs.enclosed"))
      end
    end
  end

  describe "Assessment Navigation" do
    it "allows switching between different assessment tabs" do
      # Define tabs to test with their corresponding i18n bases
      tabs_to_test = {
        "user_height" => "forms.tallest_user_height",
        "structure" => "forms.structure",
        "materials" => "forms.materials",
        "anchorage" => "forms.anchorage",
        "fan" => "forms.fan",
        "general" => "forms.inspections"
      }

      # Add slide tab if inspection has slide
      if slide_inspection.has_slide
        tabs_to_test["slide"] = "forms.slide"
      end

      # Ensure inspection has a unit (required for some tabs)
      expect(inspection.unit).to be_present

      # Start with general tab
      visit edit_inspection_path(inspection)

      # Test each tab navigation
      tabs_to_test.each do |tab_name, i18n_base|
        # For slide tab, we need to use the slide inspection
        if tab_name == "slide"
          visit edit_inspection_path(slide_inspection, tab: "slide")
        else
          # Check if we're already on this tab
          current_tab_matches = current_url.include?("tab=#{tab_name}")

          # Skip clicking if we're already on this tab
          unless current_tab_matches
            click_link I18n.t("inspections.tabs.#{tab_name}")
          end
        end

        # Verify we're on the correct tab
        expect(current_url).to include("tab=#{tab_name}")

        # Verify the form content matches i18n structure
        expect_form_matches_i18n(i18n_base)

        # Verify submit button is present
        expect(page).to have_button(I18n.t("#{i18n_base}.submit"))

        # Verify no missing translations
        expect(page).not_to have_content("translation missing")

        # Special case for user_height - check for specific content
        if tab_name == "user_height"
          expect(page).to have_content("Total Capacity")
        end
      end

      # Test enclosed tab separately since it needs a different inspection
      if enclosed_inspection.is_totally_enclosed
        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")
        expect(current_url).to include("tab=enclosed")
        expect_form_matches_i18n("forms.enclosed")
        expect(page).to have_button(I18n.t("forms.enclosed.submit"))
        expect(page).not_to have_content("translation missing")
      end
    end

    context "for totally enclosed units" do
      it "includes enclosed tab in navigation" do
        visit edit_inspection_path(enclosed_inspection)

        # Should have enclosed tab
        expect(page).to have_link(I18n.t("inspections.tabs.enclosed"))

        # Can navigate to enclosed assessment
        click_link I18n.t("inspections.tabs.enclosed")
        expect_form_matches_i18n("forms.enclosed")
      end
    end

    it "maintains correct tab state in URL" do
      visit edit_inspection_path(inspection, tab: "structure")
      expect(current_url).to include("tab=structure")

      click_link I18n.t("inspections.tabs.materials")
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
        lock_stitch_pass: true,
        air_loss_pass: false,
        straight_walls_pass: true,
        sharp_edges_pass: true,
        unit_stable_pass: true,
        stitch_length: 10.0,
        unit_pressure_value: 500.0
      )

      visit edit_inspection_path(inspection, tab: "structure")

      expect(page).to have_css(".assessment-summary")
      # Structure assessment summary is displayed
      expect(page).to have_css(".completion-percentage")
      expect(page).to have_css(".checks-count")
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

      expect(page).to have_css(".material-compliance-summary")
      # Materials assessment summary is displayed
      expect(page).to have_css(".critical-materials")
      expect(page).to have_css(".overall-materials")
      expect(page).to have_css(".completion-percentage")
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

      expect(page).to have_css(".anchorage-assessment-summary")
      # Anchorage assessment summary is displayed
      expect(page).to have_css(".completion-status")
      expect(page).to have_css(".safety-checks")
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

        expect(page).to have_css(".assessment-summary")
        # Enclosed assessment summary is displayed
        expect(page).to have_css(".completion-percentage")
        expect(page).to have_css(".checks-count")
      end
    end
  end

  describe "Form Functionality" do
    it "saves slide assessment data when form is submitted" do
      visit edit_inspection_path(inspection, tab: "slide")

      fill_in I18n.t("forms.slide.fields.slide_platform_height"), with: "2.5"
      click_button I18n.t("forms.slide.submit")

      expect(page).to have_content(I18n.t("inspections.messages.updated"))
      inspection.reload
      expect(inspection.slide_assessment.slide_platform_height).to eq(2.5)
    end
  end

  describe "Assessment Status Display" do
    it "shows assessment status when assessments are persisted" do
      # Visit the edit page to create the assessments
      visit edit_inspection_path(inspection)

      # Update the assessments that were automatically created
      inspection.slide_assessment.update!(slide_platform_height: 2.0)
      inspection.user_height_assessment.update!(containing_wall_height: 1.5)
      inspection.structure_assessment.update!(seam_integrity_pass: true, stitch_length: 10.0)
      inspection.materials_assessment.update!(fabric_strength_pass: true)
      inspection.anchorage_assessment.update!(num_low_anchors: 4)
      inspection.fan_assessment.update!(blower_serial: "FAN123")

      visit edit_inspection_path(inspection, tab: "slide")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(inspection, tab: "user_height")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(inspection, tab: "structure")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(inspection, tab: "materials")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(inspection, tab: "anchorage")
      expect(page).to have_css(".assessment-status")

      visit edit_inspection_path(inspection, tab: "fan")
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
      # Create a fresh inspection that hasn't been visited
      fresh_inspection = create(:inspection, user: user)

      # Verify assessments exist but are empty (no data filled in)
      expect(fresh_inspection.slide_assessment).to be_present
      expect(fresh_inspection.slide_assessment.slide_platform_height).to be_nil

      visit edit_inspection_path(fresh_inspection, tab: "slide")
      # Assessment status shows even when empty since assessments are auto-created
      expect(page).to have_css(".assessment-status")
      # Should show 0% completion for empty assessment
      expect(page).to have_content("Completion: 0%")
    end
  end

  private

  def expect_assessment_form_rendered(tab_name)
    # Map tab names to i18n keys where they differ
    i18n_key = case tab_name
    when "user_height"
      "tallest_user_height"
    else
      tab_name
    end

    expect(page).to have_css("h1", text: I18n.t("forms.#{i18n_key}.header"))
    expect(page).not_to have_content("translation missing")
    expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
  end
end
