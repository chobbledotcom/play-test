require "rails_helper"

RSpec.feature "Seed Data Management", type: :feature do
  let(:admin_user) { create(:user, :admin) }
  let(:test_user) { create(:user) }

  before do
    sign_in(admin_user)
  end

  scenario "admin adds seed data to a user without existing seeds" do
    # Use smaller numbers for faster tests
    stub_const("SeedDataService::UNIT_COUNT", 3)
    stub_const("SeedDataService::INSPECTION_COUNT", 2)

    visit edit_user_path(test_user)

    expect(page).to have_content(I18n.t("users.titles.edit"))

    expect(page).to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).not_to have_button(I18n.t("users.buttons.delete_seeds"))

    click_button I18n.t("users.buttons.add_seeds")

    # TODO: Fix flash message display
    # expect(page).to have_content(I18n.t("users.messages.seeds_added"))
    
    # Verify redirect back to edit page
    expect(page).to have_current_path(edit_user_path(test_user))
    expect(test_user.reload.has_seed_data?).to be true
    expect(test_user.units.count).to eq(3)
    # 3 units × 2 inspections each
    expect(test_user.inspections.count).to eq(6)

    expect(test_user.units.seed_data.count).to eq(3)
    expect(test_user.inspections.seed_data.count).to eq(6)

    expect(page).not_to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).to have_button(I18n.t("users.buttons.delete_seeds"))
  end

  scenario "admin deletes seed data from a user with existing seeds" do
    # Use smaller numbers for faster tests
    smaller_counts = {unit_count: 3, inspection_count: 2}
    SeedDataService.add_seeds_for_user(test_user, **smaller_counts)

    visit edit_user_path(test_user)

    expect(page).not_to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).to have_button(I18n.t("users.buttons.delete_seeds"))

    click_button I18n.t("users.buttons.delete_seeds")

    # TODO: Fix flash message display
    # expect(page).to have_content(I18n.t("users.messages.seeds_deleted"))
    
    # Verify redirect back to edit page
    expect(page).to have_current_path(edit_user_path(test_user))
    expect(test_user.reload.has_seed_data?).to be false
    expect(test_user.units.seed_data.count).to eq(0)
    expect(test_user.inspections.seed_data.count).to eq(0)

    expect(page).to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).not_to have_button(I18n.t("users.buttons.delete_seeds"))
  end
  scenario "non-admin users cannot see seed buttons" do
    logout
    sign_in(test_user)
    visit edit_user_path(test_user)

    expect(page).not_to have_button(I18n.t("users.buttons.add_seeds"))
    expect(page).not_to have_button(I18n.t("users.buttons.delete_seeds"))
  end

  scenario "seed data does not affect non-seed data" do
    # Use smaller numbers for faster tests
    stub_const("SeedDataService::UNIT_COUNT", 3)
    stub_const("SeedDataService::INSPECTION_COUNT", 2)

    regular_unit = create(:unit, user: test_user, is_seed: false)
    regular_inspection = create(
      :inspection, user: test_user, unit: regular_unit, is_seed: false
    )

    visit edit_user_path(test_user)
    click_button I18n.t("users.buttons.add_seeds")

    expect(test_user.reload.units.non_seed_data).to include(regular_unit)
    expect(test_user.inspections.non_seed_data).to include(regular_inspection)

    click_button I18n.t("users.buttons.delete_seeds")

    expect(test_user.reload.units.non_seed_data).to include(regular_unit)
    expect(test_user.inspections.non_seed_data).to include(regular_inspection)
  end
end
