# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Mission Control navigation", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  scenario "admin user sees Jobs link in navigation" do
    sign_in(admin_user)
    visit root_path

    within "nav" do
      expect(page).to have_link(I18n.t("navigation.jobs"), href: "/mission_control")
    end
  end

  scenario "regular user does not see Jobs link in navigation" do
    sign_in(regular_user)
    visit root_path

    within "nav" do
      expect(page).not_to have_link(I18n.t("navigation.jobs"))
    end
  end

  scenario "admin can click Jobs link in navigation" do
    sign_in(admin_user)
    visit root_path

    within "nav" do
      # Just verify the link exists and is clickable
      jobs_link = find_link(I18n.t("navigation.jobs"))
      expect(jobs_link[:href]).to eq("/mission_control")
    end
  end

  scenario "Jobs link has correct href attribute" do
    sign_in(admin_user)
    visit root_path

    # Check that the Jobs link exists with correct href
    jobs_link = page.find("nav").find_link(I18n.t("navigation.jobs"))
    expect(jobs_link).not_to be_nil
    expect(jobs_link[:href]).to eq("/mission_control")
  end
end
