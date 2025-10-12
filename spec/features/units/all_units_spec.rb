# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "All Units Admin Page", type: :feature do
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:regular_user) { create(:user, email: "user@example.com") }

  describe "accessing all units page" do
    before do
      create(:unit, user: regular_user, name: "User Unit", serial: "USER001")
      create(:unit, user: admin_user, name: "Admin Unit", serial: "ADMIN001")
    end

    context "when logged in as admin" do
      before do
        sign_in(admin_user)
        visit units_path
      end

      scenario "shows All Units button on regular units page" do
        expect(page).to have_button(I18n.t("units.buttons.all_units"))
      end

      scenario "navigates to all units page" do
        click_button I18n.t("units.buttons.all_units")

        expect(current_path).to eq(all_units_path)
        expect(page).to have_content(I18n.t("units.titles.all_units"))
      end

      scenario "shows all units from all users" do
        visit all_units_path

        expect(page).to have_content("User Unit")
        expect(page).to have_content("Admin Unit")
        expect(page).to have_content("USER001")
        expect(page).to have_content("ADMIN001")
      end

      scenario "does not show All Units button on all units page" do
        visit all_units_path

        expect(page).not_to have_button(I18n.t("units.buttons.all_units"))
      end

      scenario "allows searching across all units" do
        visit all_units_path(query: "User Unit")

        expect(page).to have_content("User Unit")
        expect(page).not_to have_content("Admin Unit")
      end

      scenario "filter form submits to all units path" do
        visit all_units_path

        expect(page).to have_selector("form[action='#{all_units_path}']")
      end
    end

    context "when logged in as regular user" do
      before do
        sign_in(regular_user)
      end

      scenario "does not show All Units button" do
        visit units_path

        expect(page).not_to have_button(I18n.t("units.buttons.all_units"))
      end

      scenario "returns 404 when accessing all units page directly" do
        visit all_units_path

        expect(page.status_code).to eq(404)
      end
    end

    context "when not logged in" do
      scenario "redirects to login page" do
        visit all_units_path

        expect(current_path).to eq(login_path)
      end
    end
  end
end
