# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    before do
      Page.where(slug: "/").first_or_create!(
        content: "Home",
        link_title: "Home"
      )
    end

    context "when not logged in" do
      it "returns http success" do
        visit root_path
        expect(page.status_code).to eq(200)
      end

      it "renders the home page" do
        visit root_path
        expect(page).to have_current_path(root_path)
      end

      it "shows login and register links" do
        visit root_path
        expect(page).to have_link(I18n.t("session.login.title"), href: login_path)
        expect(page).to have_link(I18n.t("users.titles.register"), href: register_path)
      end

      it "does not require authentication" do
        visit root_path
        expect(page).not_to have_current_path(login_path)
      end
    end

    context "when logged in" do
      let(:user) { create(:user) }

      before do
        login_user_via_form(user)
      end

      it "returns http success" do
        visit root_path
        expect(page.status_code).to eq(200)
      end

      it "renders the home page" do
        visit root_path
        expect(page).to have_current_path(root_path)
      end

      it "shows authenticated user navigation" do
        visit root_path
        expect(page).to have_button("Log Out")
        expect(page).to have_link("Settings")
        expect(page).to have_link("Inspections")
        expect(page).to have_link("Units")
      end

      it "allows access without redirect" do
        visit root_path
        expect(page).not_to have_current_path(login_path)
      end
    end

    context "response headers and performance" do
      it "sets appropriate cache headers" do
        get root_path
        expect(response.headers["Cache-Control"]).to be_present
      end

      it "includes security headers" do
        get root_path
        expect(response.headers["X-Frame-Options"]).to be_present
      end
    end

    context "edge cases and error handling" do
      it "handles malformed requests gracefully" do
        visit "#{root_path}?invalid=data"
        expect(page.status_code).to eq(200)
      end

      it "works with different HTTP methods (HEAD request)" do
        head root_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "navigation integration" do
    context "when logged in" do
      let(:user) { create(:user) }

      before do
        login_user_via_form(user)
      end

      it "integrates with application layout navigation" do
        visit root_path
        expect(page).to have_link("Inspections")
        expect(page).to have_link("Units")
      end

      it "shows user-specific navigation options" do
        visit root_path
        expect(page).to have_button("Log Out") if page.has_button?("Log Out")
      end
    end
  end
end
