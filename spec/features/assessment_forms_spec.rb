require "rails_helper"

RSpec.feature "Assessment Forms", type: :feature do
  let(:admin_user) { create(:user, :without_company, email: "admin@testcompany.com") }
  let(:inspection_company) { create(:inspector_company, name: "Test Company") }
  let(:user) { create(:user, inspection_company: inspection_company) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, unit: unit, user: user) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    sign_in(user)
  end

  describe "Assessment Form Rendering" do
    it "renders slide assessment form without i18n errors" do
      visit edit_inspection_path(inspection, tab: "slide")

      expect(page).to have_css("h1", text: I18n.t("inspections.assessments.slide.title"))
      expect(page).to have_css(".slide-assessment")
      expect(page).not_to have_content("translation missing")
      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    it "renders user height assessment form without i18n errors" do
      visit edit_inspection_path(inspection, tab: "user_height")

      expect(page).to have_css("h1", text: I18n.t("inspections.assessments.user_height.title"))
      expect(page).to have_css(".user-height-assessment")
      expect(page).not_to have_content("translation missing")
      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    it "renders structure assessment form without i18n errors" do
      visit edit_inspection_path(inspection, tab: "structure")

      expect(page).to have_css("h1", text: I18n.t("inspections.assessments.structure.title"))
      expect(page).to have_css(".structure-assessment")
      expect(page).not_to have_content("translation missing")
      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    it "renders materials assessment form without i18n errors" do
      visit edit_inspection_path(inspection, tab: "materials")

      expect(page).to have_css("h1", text: I18n.t("inspections.assessments.materials.title"))
      expect(page).to have_css(".materials-assessment")
      expect(page).not_to have_content("translation missing")
      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    it "renders anchorage assessment form without i18n errors" do
      visit edit_inspection_path(inspection, tab: "anchorage")

      expect(page).to have_css("h1", text: I18n.t("inspections.assessments.anchorage.title"))
      expect(page).to have_css(".anchorage-assessment")
      expect(page).not_to have_content("translation missing")
      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    it "renders fan assessment form without i18n errors" do
      visit edit_inspection_path(inspection, tab: "fan")

      expect(page).to have_css("h1", text: I18n.t("inspections.assessments.fan.title"))
      expect(page).to have_css(".fan-assessment")
      expect(page).not_to have_content("translation missing")
      expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
    end

    context "for totally enclosed units" do
      let(:enclosed_unit) { create(:unit, user: user, is_totally_enclosed: true) }
      let(:enclosed_inspection) { create(:inspection, unit: enclosed_unit, user: user) }

      it "renders enclosed assessment form without i18n errors" do
        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")

        expect(page).to have_css("h1", text: I18n.t("inspections.assessments.enclosed.title"))
        expect(page).to have_css(".enclosed-assessment")
        expect(page).not_to have_content("translation missing")
        expect(page).to have_button(I18n.t("inspections.buttons.save_assessment"))
      end

      it "shows enclosed tab only for totally enclosed units" do
        visit edit_inspection_path(enclosed_inspection)
        expect(page).to have_link(I18n.t("inspections.tabs.enclosed"))

        # Regular inspection should not have enclosed tab
        visit edit_inspection_path(inspection)
        expect(page).not_to have_link(I18n.t("inspections.tabs.enclosed"))
      end
    end
  end

  describe "Assessment Form Content" do
    it "displays slide assessment form sections" do
      visit edit_inspection_path(inspection, tab: "slide")

      # Check for major sections
      expect(page).to have_content(I18n.t("inspections.assessments.slide.sections.slide_measurements"))
      expect(page).to have_content(I18n.t("inspections.assessments.slide.sections.safety_checks"))

      # Check for basic form elements
      expect(page).to have_css("input[type='number']")
      expect(page).to have_css("input[type='radio']")
      expect(page).to have_css("input[type='checkbox']")

      # Check for comment toggle functionality (textarea hidden by default)
      expect(page).to have_css("input[data-comment-toggle]")
    end

    it "displays user height assessment form sections" do
      visit edit_inspection_path(inspection, tab: "user_height")

      # Check for major sections
      expect(page).to have_content(I18n.t("inspections.assessments.user_height.sections.height_measurements"))
      expect(page).to have_content(I18n.t("inspections.assessments.user_height.sections.user_capacity"))
      expect(page).to have_content(I18n.t("inspections.assessments.user_height.sections.play_area"))

      # Check for basic form elements
      expect(page).to have_css("input[type='number']")
      expect(page).to have_css("input[type='checkbox']")

      # Check for comment toggle functionality (textarea hidden by default)
      expect(page).to have_css("input[data-comment-toggle]")
    end

    it "displays structure assessment form sections" do
      visit edit_inspection_path(inspection, tab: "structure")

      # Check for major sections
      expect(page).to have_content(I18n.t("inspections.assessments.structure.sections.critical_safety_checks"))
      expect(page).to have_content(I18n.t("inspections.assessments.structure.sections.measurements"))
      expect(page).to have_content(I18n.t("inspections.assessments.structure.sections.additional_safety_checks"))

      # Check for basic form elements
      expect(page).to have_css("input[type='number']")
      expect(page).to have_css("input[type='radio']")
    end

    it "displays materials assessment form sections" do
      visit edit_inspection_path(inspection, tab: "materials")

      # Check for major sections
      expect(page).to have_content(I18n.t("inspections.assessments.materials.sections.rope_specifications"))
      expect(page).to have_content(I18n.t("inspections.assessments.materials.sections.critical_materials"))
      expect(page).to have_content(I18n.t("inspections.assessments.materials.sections.additional_materials"))

      # Check for basic form elements
      expect(page).to have_css("input[type='number']")
      expect(page).to have_css("input[type='radio']")
    end

    it "displays anchorage assessment form sections" do
      visit edit_inspection_path(inspection, tab: "anchorage")

      # Check for major sections
      expect(page).to have_content(I18n.t("inspections.assessments.anchorage.sections.anchor_counts"))
      expect(page).to have_content(I18n.t("inspections.assessments.anchorage.sections.anchor_quality"))

      # Check for basic form elements
      expect(page).to have_css("input[type='number']")
      expect(page).to have_css("input[type='radio']")
    end

    it "displays fan assessment form sections" do
      visit edit_inspection_path(inspection, tab: "fan")

      # Check for major sections
      expect(page).to have_content(I18n.t("inspections.assessments.fan.sections.blower_specifications"))
      expect(page).to have_content(I18n.t("inspections.assessments.fan.sections.blower_safety_checks"))

      # Check for basic form elements
      expect(page).to have_css("input[type='radio']")
      expect(page).to have_css("input[type='text']")

      # Check for comment toggle functionality (textarea hidden by default)
      expect(page).to have_css("input[data-comment-toggle]")
    end

    context "for totally enclosed units" do
      let(:enclosed_unit) { create(:unit, user: user, is_totally_enclosed: true) }
      let(:enclosed_inspection) { create(:inspection, unit: enclosed_unit, user: user) }

      it "displays enclosed assessment form sections" do
        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")

        # Check for major sections
        expect(page).to have_content(I18n.t("inspections.assessments.enclosed.sections.exit_requirements"))

        # Check for form fields
        expect(page).to have_field(I18n.t("inspections.assessments.enclosed.fields.exit_number"))
        expect(page).to have_content(I18n.t("inspections.assessments.enclosed.fields.exit_number_pass"))
        expect(page).to have_content(I18n.t("inspections.assessments.enclosed.fields.exit_visible_pass"))

        # Check for basic form elements
        expect(page).to have_css("input[type='number']")
        expect(page).to have_css("input[type='radio']")

        # Check for comment toggle functionality (textarea hidden by default)
        expect(page).to have_css("input[data-comment-toggle]")
      end
    end
  end

  describe "Assessment Navigation" do
    it "allows switching between different assessment tabs" do
      visit edit_inspection_path(inspection, tab: "slide")
      expect(page).to have_css(".slide-assessment")

      click_link I18n.t("inspections.tabs.user_height")
      expect(page).to have_css(".user-height-assessment")

      click_link I18n.t("inspections.tabs.structure")
      expect(page).to have_css(".structure-assessment")

      click_link I18n.t("inspections.tabs.materials")
      expect(page).to have_css(".materials-assessment")

      click_link I18n.t("inspections.tabs.anchorage")
      expect(page).to have_css(".anchorage-assessment")

      click_link I18n.t("inspections.tabs.fan")
      expect(page).to have_css(".fan-assessment")

      click_link I18n.t("inspections.tabs.general")
      expect(page).to have_css("form") # General form
    end

    context "for totally enclosed units" do
      let(:enclosed_unit) { create(:unit, user: user, is_totally_enclosed: true) }
      let(:enclosed_inspection) { create(:inspection, unit: enclosed_unit, user: user) }

      it "includes enclosed tab in navigation" do
        visit edit_inspection_path(enclosed_inspection)

        # Should have enclosed tab
        expect(page).to have_link(I18n.t("inspections.tabs.enclosed"))

        # Can navigate to enclosed assessment
        click_link I18n.t("inspections.tabs.enclosed")
        expect(page).to have_css(".enclosed-assessment")
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
      create(:structure_assessment,
        inspection: inspection,
        seam_integrity_pass: true,
        lock_stitch_pass: true,
        air_loss_pass: false,
        stitch_length: 15.0)

      visit edit_inspection_path(inspection, tab: "structure")

      expect(page).to have_css(".assessment-summary")
      expect(page).to have_content(I18n.t("inspections.assessments.structure.title"))
      expect(page).to have_css(".completion-percentage")
      expect(page).to have_css(".checks-count")
    end

    it "shows material compliance summary for materials assessment with data" do
      create(:materials_assessment,
        inspection: inspection,
        fabric_pass: true,
        fire_retardant_pass: false,
        thread_pass: true,
        rope_size: 25.0,
        rope_size_pass: true)

      visit edit_inspection_path(inspection, tab: "materials")

      expect(page).to have_css(".material-compliance-summary")
      expect(page).to have_content(I18n.t("inspections.assessments.materials.title"))
      expect(page).to have_css(".critical-materials")
      expect(page).to have_css(".overall-materials")
      expect(page).to have_css(".completion-percentage")
    end

    it "shows anchorage assessment summary for anchorage assessment with data" do
      create(:anchorage_assessment,
        inspection: inspection,
        num_low_anchors: 4,
        num_high_anchors: 2,
        anchor_type_pass: true,
        pull_strength_pass: false)

      visit edit_inspection_path(inspection, tab: "anchorage")

      expect(page).to have_css(".anchorage-assessment-summary")
      expect(page).to have_content(I18n.t("inspections.assessments.anchorage.title"))
      expect(page).to have_css(".completion-status")
      expect(page).to have_css(".safety-checks")
    end

    context "for totally enclosed units" do
      let(:enclosed_unit) { create(:unit, user: user, is_totally_enclosed: true) }
      let(:enclosed_inspection) { create(:inspection, unit: enclosed_unit, user: user) }

      it "shows enclosed assessment summary for enclosed assessment with data" do
        create(:enclosed_assessment,
          inspection: enclosed_inspection,
          exit_number: 2,
          exit_number_pass: true,
          exit_visible_pass: false)

        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")

        expect(page).to have_css(".assessment-summary")
        expect(page).to have_content(I18n.t("inspections.assessments.enclosed.title"))
        expect(page).to have_css(".completion-percentage")
        expect(page).to have_css(".checks-count")
      end
    end
  end

  describe "Form Functionality" do
    it "displays form error handling structure" do
      visit edit_inspection_path(inspection, tab: "slide")

      # Check that error display structure exists (even if no errors currently)
      expect(page).to have_css("form") # Form exists
    end
  end

  describe "Assessment Status Display" do
    it "shows assessment status when assessments are persisted" do
      # Create persisted assessments
      create(:slide_assessment, inspection: inspection, slide_platform_height: 2.0)
      create(:user_height_assessment, inspection: inspection, containing_wall_height: 1.5)
      create(:structure_assessment, inspection: inspection, seam_integrity_pass: true)
      create(:materials_assessment, inspection: inspection, fabric_pass: true)
      create(:anchorage_assessment, inspection: inspection, anchor_type_pass: true)
      create(:fan_assessment, inspection: inspection, pat_pass: true)

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
      let(:enclosed_unit) { create(:unit, user: user, is_totally_enclosed: true) }
      let(:enclosed_inspection) { create(:inspection, unit: enclosed_unit, user: user) }

      it "shows assessment status for enclosed assessments" do
        create(:enclosed_assessment, inspection: enclosed_inspection, exit_number: 2)

        visit edit_inspection_path(enclosed_inspection, tab: "enclosed")
        expect(page).to have_css(".assessment-status")
      end
    end

    it "does not show assessment status when no assessments exist" do
      visit edit_inspection_path(inspection, tab: "slide")
      expect(page).not_to have_css(".assessment-status")
    end
  end
end
