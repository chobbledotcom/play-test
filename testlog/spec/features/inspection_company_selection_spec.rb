require "rails_helper"

RSpec.feature "Inspector Company Selection", type: :feature do
  let(:inspector_company) { create(:inspector_company, active: true) }
  let(:user) { create(:user, :without_company, inspection_company: inspector_company) }
  let(:admin_user) { create(:user, :admin, :without_company, inspection_company: inspector_company) }
  let(:unit) { create(:unit, user: user) }
  let(:admin_unit) { create(:unit, user: admin_user) }
  let(:another_company) { create(:inspector_company, name: "Another Company", active: true) }

  describe "Creating new inspection from unit page" do
    before do
      # Login as the regular user for these tests
      login_user_via_form(user)
    end
    it "creates draft inspection with user's inspector company through unit page" do
      visit unit_path(unit)

      click_button I18n.t("units.buttons.add_inspection")

      # Should redirect to edit page with draft inspection
      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)
      inspection = user.inspections.last
      expect(inspection.inspector_company_id).to eq(inspector_company.id)
      expect(inspection.status).to eq("draft")
      expect(inspection.unit).to eq(unit)
    end

    it "shows read-only inspector company field for regular users" do
      # Create inspection from unit page
      visit unit_path(unit)
      click_button I18n.t("units.buttons.add_inspection")

      # Should be on edit page now
      expect(page).to have_current_path(/\/inspections\/[A-Z0-9]+\/edit/)

      # Regular users should see read-only field, not dropdown
      expect(page).not_to have_select("inspection[inspector_company_id]")
      expect(page).to have_content(inspector_company.name)
      expect(page).to have_content("Set in your user settings")
    end
  end

  describe "Editing existing inspection" do
    before do
      # Login as admin user for these tests since they need dropdown access
      login_user_via_form(admin_user)
    end

    let(:inspection) { create(:inspection, user: admin_user, unit: admin_unit, status: "draft") }

    context "changing inspector company" do
      it "allows changing inspector company on draft inspection" do
        # Ensure the inspector company exists and is created
        inspector_company.reload
        expect(inspector_company.active).to be true

        visit edit_inspection_path(inspection)

        # Change to a different inspector company
        select inspector_company.name, from: "inspection[inspector_company_id]"
        click_button I18n.t("inspections.buttons.update")

        expect(page).to have_content(I18n.t("inspections.messages.updated"))
        inspection.reload
        expect(inspection.inspector_company).to eq(inspector_company)
      end

      it "allows changing between different companies" do
        # Ensure both companies exist and are active
        inspector_company.reload
        another_company.reload
        expect(inspector_company.active).to be true
        expect(another_company.active).to be true

        inspection.update!(inspector_company: inspector_company)
        visit edit_inspection_path(inspection)

        expect(page).to have_select("inspection[inspector_company_id]",
          selected: inspector_company.name)

        select another_company.name, from: "inspection[inspector_company_id]"
        click_button I18n.t("inspections.buttons.update")

        expect(page).to have_content(I18n.t("inspections.messages.updated"))
        inspection.reload
        expect(inspection.inspector_company).to eq(another_company)
      end

      # FIXME: This test needs to be fixed - the prompt option isn't available once another option is selected
      # it "allows removing inspector company from draft inspection" do
      #   # Ensure companies exist first
      #   inspector_company.reload
      #   expect(inspector_company.active).to be true
      #
      #   inspection.update!(inspector_company: inspector_company)
      #   visit edit_inspection_path(inspection)
      #
      #   # Select the prompt option (which has empty value)
      #   find('select[name="inspection[inspector_company_id]"]').find('option[value=""]').select_option
      #   click_button I18n.t('inspections.buttons.update')
      #
      #   expect(page).to have_content("Inspection record updated")
      #   inspection.reload
      #   expect(inspection.inspector_company_id).to be_nil
      # end
    end

    context "status transitions with inspector company validation" do
      it "allows marking inspection as complete with inspector company" do
        # First create all necessary assessments for completion
        create(:user_height_assessment, :complete, inspection: inspection)
        create(:structure_assessment, :complete, inspection: inspection)
        create(:anchorage_assessment, :passed, inspection: inspection)
        create(:materials_assessment, :passed, inspection: inspection)
        create(:fan_assessment, :passed, inspection: inspection)

        visit edit_inspection_path(inspection)

        # Complete with inspector company (should work since inspection already has one)
        click_button I18n.t("inspections.buttons.mark_complete")

        expect(page).to have_content(I18n.t("inspections.messages.marked_complete"))
        inspection.reload
        expect(inspection.status).to eq("complete")
      end

      it "allows completing inspection when inspector company is selected" do
        # Ensure company exists and is active
        inspector_company.reload
        expect(inspector_company.active).to be true

        # First create all necessary assessments for completion
        create(:user_height_assessment, :complete, inspection: inspection)
        create(:structure_assessment, :complete, inspection: inspection)
        create(:anchorage_assessment, :passed, inspection: inspection)
        create(:materials_assessment, :passed, inspection: inspection)
        create(:fan_assessment, :passed, inspection: inspection)

        visit edit_inspection_path(inspection)

        # Inspector company is already set, just mark complete
        click_button I18n.t("inspections.buttons.mark_complete")

        expect(page).to have_content(I18n.t("inspections.messages.marked_complete"))
        inspection.reload
        expect(inspection.status).to eq("complete")
        expect(inspection.inspector_company).to eq(inspector_company)
      end

      it "can mark complete inspection as draft again" do
        # First make it complete
        inspection.update!(status: "complete")

        visit inspection_path(inspection)

        click_button I18n.t("inspections.buttons.mark_draft")

        expect(page).to have_content(I18n.t("inspections.messages.marked_draft"))
        inspection.reload
        expect(inspection.status).to eq("draft")
        expect(inspection.inspector_company_id).to be_present
      end
    end
  end


  describe "Inspector company dropdown options" do
    before do
      # Login as admin user for these tests since they need dropdown access
      login_user_via_form(admin_user)
    end

    let!(:active_company) { create(:inspector_company, name: "Active Company") }
    let!(:inactive_company) { create(:inspector_company, name: "Inactive Company", active: false) }

    it "only shows active inspector companies in dropdown" do
      # Create an inspection to edit (since there's no new page)
      inspection = create(:inspection, user: admin_user, unit: admin_unit, status: "draft")
      visit edit_inspection_path(inspection)

      expect(page).to have_select("inspection[inspector_company_id]",
        with_options: [active_company.name])
      expect(page).not_to have_select("inspection[inspector_company_id]",
        with_options: [inactive_company.name])
    end

    it "orders companies alphabetically" do
      create(:inspector_company, name: "Z Company")
      create(:inspector_company, name: "A Company")

      # Create an inspection to edit (since there's no new page)
      inspection = create(:inspection, user: admin_user, unit: admin_unit, status: "draft")
      visit edit_inspection_path(inspection)

      company_options = page.all('select[name="inspection[inspector_company_id]"] option').map(&:text)
      company_names = company_options.reject { |name| name == I18n.t("inspections.fields.inspector_company_prompt") }

      expect(company_names).to eq(company_names.sort)
    end
  end
end
