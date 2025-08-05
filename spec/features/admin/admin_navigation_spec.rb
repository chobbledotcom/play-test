require "rails_helper"

RSpec.feature "Admin Navigation", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }

  scenario "admin user sees Admin link in navigation" do
    sign_in(admin_user)
    visit root_path

    expect(page).to have_link(I18n.t("navigation.admin"))
    expect(page).not_to have_link(I18n.t("navigation.users"))
    expect(page).not_to have_link(I18n.t("navigation.pages"))
    expect(page).not_to have_link(I18n.t("navigation.jobs"))
  end

  scenario "regular user does not see Admin link" do
    sign_in(regular_user)
    visit root_path

    expect(page).not_to have_link(I18n.t("navigation.admin"))
  end

  scenario "admin user can access admin dashboard" do
    sign_in(admin_user)
    visit root_path

    click_link I18n.t("navigation.admin")

    expect(page).to have_content(I18n.t("admin.title"))
    expect(page).to have_link(I18n.t("navigation.users"))
    expect(page).to have_link(I18n.t("inspector_companies.titles.index"))
    expect(page).to have_link(I18n.t("navigation.pages"))
    expect(page).to have_link(I18n.t("navigation.jobs"))
    expect(page).to have_link(I18n.t("navigation.releases"))
  end

  scenario "regular user cannot access admin path" do
    sign_in(regular_user)
    visit admin_path

    admin_required_msg = I18n.t("forms.session_new.status.admin_required")
    expect(page).to have_content(admin_required_msg)
    expect(current_path).to eq(root_path)
  end

  context "with S3 enabled" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("USE_S3_STORAGE").and_return("true")
    end

    scenario "admin sees backups link when S3 is enabled" do
      sign_in(admin_user)
      visit admin_path

      expect(page).to have_link(I18n.t("navigation.backups"))
    end
  end

  context "without S3 enabled" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("USE_S3_STORAGE").and_return(nil)
    end

    scenario "admin does not see backups link when S3 is disabled" do
      sign_in(admin_user)
      visit admin_path

      expect(page).not_to have_link(I18n.t("navigation.backups"))
    end
  end
end
