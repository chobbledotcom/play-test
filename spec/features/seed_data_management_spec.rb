require "rails_helper"

RSpec.feature "Seed Data Management", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:test_user) { create(:user) }

  before do
    sign_in(admin_user)
  end

  scenario "admin adds seed data to a user without existing seeds" do
    visit edit_user_path(test_user)

    # Debug: Check if we're on the right page
    expect(page).to have_content(I18n.t("users.titles.edit"))

    expect(page).to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).not_to have_button(I18n.t("users.buttons.delete_seeds"))

    click_button I18n.t("users.buttons.add_seeds")

    expect(page).to have_content(I18n.t("users.messages.seeds_added"))
    expect(test_user.reload.has_seed_data?).to be true
    expect(test_user.units.count).to eq(20)
    expect(test_user.inspections.count).to eq(100) # 20 units × 5 inspections each

    # Check that all data is marked as seed
    expect(test_user.units.seed_data.count).to eq(20)
    expect(test_user.inspections.seed_data.count).to eq(100)

    # Check button has changed
    expect(page).not_to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).to have_button(I18n.t("users.buttons.delete_seeds"))
  end

  scenario "admin deletes seed data from a user with existing seeds" do
    # First add seed data
    SeedDataService.add_seeds_for_user(test_user)

    visit edit_user_path(test_user)

    expect(page).not_to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).to have_button(I18n.t("users.buttons.delete_seeds"))

    # RackTest doesn't support accept_confirm, just click the button
    click_button I18n.t("users.buttons.delete_seeds")

    expect(page).to have_content(I18n.t("users.messages.seeds_deleted"))
    expect(test_user.reload.has_seed_data?).to be false
    expect(test_user.units.seed_data.count).to eq(0)
    expect(test_user.inspections.seed_data.count).to eq(0)

    # Check button has changed back
    expect(page).to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).not_to have_button(I18n.t("users.buttons.delete_seeds"))
  end

  scenario "seed inspections are properly backdated" do
    visit edit_user_path(test_user)
    click_button I18n.t("users.buttons.add_seeds")

    unit = test_user.reload.units.seed_data.first
    inspections = unit.inspections.order(:inspection_date)

    # Check we have 5 inspections
    expect(inspections.count).to eq(5)

    # Check they're properly spaced
    inspections.each_cons(2) do |older, newer|
      # DateTime subtraction gives seconds, so divide by seconds per day
      days_between = ((newer.inspection_date - older.inspection_date) / 1.day).to_i
      # Should be exactly 364 days apart
      expect(days_between).to eq(364)
    end
  end

  scenario "non-admin users cannot see seed buttons" do
    sign_in(test_user)
    visit edit_user_path(test_user)

    expect(page).not_to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).not_to have_button(I18n.t("users.buttons.delete_seeds"))
  end

  scenario "seed data does not affect non-seed data" do
    # Create some regular data
    regular_unit = create(:unit, user: test_user, is_seed: false)
    regular_inspection = create(:inspection, user: test_user, unit: regular_unit, is_seed: false)

    visit edit_user_path(test_user)
    click_button I18n.t("users.buttons.add_seeds")

    # Regular data should still exist
    expect(test_user.reload.units.non_seed_data).to include(regular_unit)
    expect(test_user.inspections.non_seed_data).to include(regular_inspection)

    # Now delete seed data
    click_button I18n.t("users.buttons.delete_seeds")

    # Regular data should still exist
    expect(test_user.reload.units.non_seed_data).to include(regular_unit)
    expect(test_user.inspections.non_seed_data).to include(regular_inspection)
  end
end
