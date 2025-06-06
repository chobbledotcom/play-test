require "rails_helper"

RSpec.feature "Inspection Company Assignment", type: :feature do
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:regular_user) { create(:user, :without_company, email: "user@example.com") }
  let!(:inspector_company) { create(:inspector_company, active: true) }

  before do
    # Set up admin pattern to make admin_user an admin
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
  end

  describe "Admin assigning inspection company to user" do
    before { sign_in admin_user }

    scenario "Admin can assign inspection company to user" do
      visit edit_user_path(regular_user)

      expect(page).to have_select("user_inspection_company_id")
      select inspector_company.name, from: "user_inspection_company_id"
      click_button "Update User"

      expect(page).to have_content("User updated")
      regular_user.reload
      expect(regular_user.inspection_company_id).to eq(inspector_company.id)
    end
  end

  describe "Non-admin user restrictions" do
    before { sign_in regular_user }

    scenario "Regular user cannot see inspection company field in settings" do
      visit change_settings_user_path(regular_user)

      expect(page).not_to have_select("user_inspection_company_id")
      expect(page).not_to have_content("Inspection Company")
    end

    scenario "Regular user cannot access admin user edit page" do
      visit edit_user_path(regular_user)

      expect(page).to have_content(I18n.t("inspector_companies.messages.unauthorized"))
      expect(current_path).to eq(root_path)
    end
  end

  describe "Inspection creation restrictions" do
    context "when user has no inspection company assigned" do
      before { sign_in regular_user }

      scenario "User cannot create inspection without company" do
        unit = create(:unit, user: regular_user)

        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        expect(page).to have_content(regular_user.inspection_company_required_message)
        expect(current_path).to eq(root_path)
      end

      scenario "User can access inspections index but sees activation message" do
        visit inspections_path

        expect(current_path).to eq(inspections_path)
        expect(page).to have_content(regular_user.inspection_company_required_message)
        expect(page).not_to have_link(I18n.t("inspections.buttons.add_via_units"))
      end
    end

    context "when user has inspection company assigned" do
      before do
        regular_user.update!(inspection_company: inspector_company)
        sign_in regular_user
      end

      scenario "User can create inspection when company is assigned" do
        unit = create(:unit, user: regular_user)

        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        # Should redirect to edit page for the new inspection
        expect(current_path).to match(/\/inspections\/\w+\/edit/)
        expect(page).not_to have_content(regular_user.inspection_company_required_message)
      end

      scenario "Created inspection has user's inspection company" do
        unit = create(:unit, user: regular_user)

        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        inspection = Inspection.last
        expect(inspection.inspector_company_id).to eq(inspector_company.id)
      end
    end
  end

  describe "Inspection form display" do
    let(:unit) { create(:unit, user: regular_user) }
    let(:admin_unit) { create(:unit, user: admin_user) }
    let(:inspection) { create(:inspection, user: regular_user, unit: unit, inspector_company: inspector_company) }
    let(:admin_inspection) { create(:inspection, user: admin_user, unit: admin_unit, inspector_company: inspector_company) }

    context "for regular users" do
      before do
        regular_user.update!(inspection_company: inspector_company)
        sign_in regular_user
      end

      scenario "Regular user sees read-only inspection company field" do
        visit edit_inspection_path(inspection)

        expect(page).not_to have_select("inspection_inspector_company_id")
        expect(page).to have_content(inspector_company.name)
        expect(page).to have_content("Set in your user settings")
      end
    end

    context "for admin users" do
      before do
        admin_user.update!(inspection_company: inspector_company)
        sign_in admin_user
      end

      scenario "Admin can edit inspection company field" do
        visit edit_inspection_path(admin_inspection)

        # Check that admin sees editable inspector company field
        expect(page).to have_content(I18n.t("inspections.fields.inspector_company"))
        # Should not see the "Set in your user settings" text that regular users see
        expect(page).not_to have_content("Set in your user settings")
      end
    end
  end
end
