require "rails_helper"

RSpec.feature "User Active Status Management", type: :feature do
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:regular_user) { create(:user, :inactive_user, email: "user@example.com") }
  let!(:inspector_company) { create(:inspector_company, active: true) }

  before do
    # Set up admin pattern to make admin_user an admin
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
  end

  describe "Admin managing user active status" do
    before { sign_in admin_user }

    scenario "Admin can set user active until date" do
      visit edit_user_path(regular_user)

      expect(page).to have_field("user_active_until")
      fill_in "user_active_until", with: (Date.current + 1.year).strftime("%Y-%m-%d")
      click_button I18n.t("users.buttons.update_user")

      expect(page).to have_content("User updated")
      regular_user.reload
      expect(regular_user.active_until).to eq(Date.current + 1.year)
    end
  end

  describe "Non-admin user restrictions" do
    before { sign_in regular_user }

    scenario "Regular user cannot see active until field in settings" do
      visit change_settings_user_path(regular_user)

      expect(page).not_to have_field("user_active_until")
      expect(page).not_to have_content("Active Until")
    end

    scenario "Regular user cannot access admin user edit page" do
      visit edit_user_path(regular_user)

      expect(page).to have_content(I18n.t("inspector_companies.messages.unauthorized"))
      expect(current_path).to eq(root_path)
    end
  end

  describe "Inspection creation restrictions" do
    context "when user is inactive" do
      before { sign_in regular_user }

      scenario "User cannot create inspection when inactive" do
        unit = create(:unit, user: regular_user)

        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        expect(page).to have_content(regular_user.inactive_user_message)
        expect(current_path).to eq(unit_path(unit))
      end

      scenario "User can access inspections index but sees inactive message" do
        visit inspections_path

        expect(current_path).to eq(inspections_path)
        expect(page).to have_content(regular_user.inactive_user_message)
        expect(page).not_to have_button(I18n.t("inspections.buttons.add_inspection"))
      end
    end

    context "when user is active" do
      before do
        regular_user.update!(active_until: Date.current + 1.year, inspection_company: inspector_company)
        sign_in regular_user
      end

      scenario "User can create inspection when active" do
        unit = create(:unit, user: regular_user)

        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        # Should redirect to edit page for the new inspection
        expect(current_path).to match(/\/inspections\/\w+\/edit/)
        expect(page).not_to have_content(regular_user.inactive_user_message)
      end

      scenario "Created inspection has user's inspection company" do
        unit = create(:unit, user: regular_user)

        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        inspection = regular_user.inspections.find_by(unit_id: unit.id)
        expect(inspection).to be_present
        expect(inspection.inspector_company_id).to eq(inspector_company.id)
      end

      scenario "User can still create inspections regardless of company changes" do
        unit = create(:unit, user: regular_user)

        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        inspection = regular_user.inspections.find_by(unit_id: unit.id)
        expect(inspection).to be_present
        
        # Active users can always create inspections
        expect(regular_user.is_active?).to be true
      end
    end
  end

  describe "Inspection form display" do
    let(:active_regular_user) { create(:user, :active_user, inspection_company: inspector_company) }
    let(:unit) { create(:unit, user: active_regular_user) }
    let(:admin_unit) { create(:unit, user: admin_user) }
    let(:inspection) { create(:inspection, user: active_regular_user, unit: unit, inspector_company: inspector_company) }
    let(:admin_inspection) { create(:inspection, user: admin_user, unit: admin_unit, inspector_company: inspector_company) }

    context "for regular users" do
      before do
        sign_in active_regular_user
      end

      scenario "Regular user does not see inspector company field" do
        visit edit_inspection_path(inspection)

        expect(page).not_to have_select("inspection_inspector_company_id")
        expect(page).not_to have_content("Inspector Company")
      end
    end

    context "for admin users" do
      before do
        admin_user.update!(inspection_company: inspector_company, active_until: nil)
        sign_in admin_user
      end

      scenario "Admin does not see inspector company field on inspection edit" do
        visit edit_inspection_path(admin_inspection)

        # Inspector company is not shown on inspection edit page
        expect(page).not_to have_content(I18n.t("inspections.fields.inspector_company"))
        expect(page).not_to have_select("inspection_inspector_company_id")
      end
    end
  end
end
