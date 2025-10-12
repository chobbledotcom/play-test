# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Badge Management", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :active_user) }

  background do
    sign_in(admin_user)
  end

  scenario "admin can access badges from admin dashboard" do
    visit admin_path

    expect(page).to have_link(I18n.t("navigation.badges"))
    click_link I18n.t("navigation.badges")

    expect(current_path).to eq(badge_batches_path)
    expect(page).to have_content(I18n.t("badges.titles.index"))
  end

  scenario "admin can create a new badge batch" do
    visit badge_batches_path

    click_link I18n.t("badges.buttons.new_batch")
    expect(page).to have_content(I18n.t("badges.titles.new"))

    fill_in I18n.t("forms.badge_batch.fields.count"), with: 10
    fill_in I18n.t("forms.badge_batch.fields.note"), with: "Test batch"

    click_button I18n.t("forms.badge_batch.submit")

    batch_created_msg = I18n.t("badges.messages.batch_created", count: 10)
    expect(page).to have_content(batch_created_msg)
    expect(page).to have_content("Test batch")
  end

  scenario "admin can view badge batch details" do
    batch = create(:badge_batch, :with_badges, note: "Sample batch")

    visit badge_batches_path
    within("li", text: batch.id.to_s) do
      click_link
    end

    expect(page).to have_content(I18n.t("badges.titles.show", id: batch.id))
    expect(page).to have_content("Sample batch")
    expect(page).to have_content(batch.count.to_s)
  end

  scenario "admin can view individual badges in a batch" do
    batch = create(:badge_batch)
    badge1 = create(:badge, badge_batch: batch)
    badge2 = create(:badge, badge_batch: batch)

    visit badge_batch_path(batch)

    expect(page).to have_content(badge1.id)
    expect(page).to have_content(badge2.id)
  end

  scenario "admin can edit badge note" do
    batch = create(:badge_batch)
    badge = create(:badge, badge_batch: batch, note: "Original note")

    visit badge_batch_path(batch)
    within("li", text: badge.id) do
      click_link
    end

    expect(page).to have_content(I18n.t("badges.titles.edit", id: badge.id))

    fill_in I18n.t("forms.badge.fields.note"), with: "Updated note"
    click_button I18n.t("forms.badge.submit")

    expect(page).to have_content(I18n.t("badges.messages.badge_updated"))
    expect(page).to have_content("Updated note")
  end

  scenario "badge batch shows correct badge count" do
    batch = create(:badge_batch, count: 3)
    create_list(:badge, 3, badge_batch: batch)

    visit badge_batches_path

    within("li", text: batch.id.to_s) do
      expect(page).to have_content("3")
    end
  end

  scenario "admin can edit badge batch note" do
    batch = create(:badge_batch, note: "Original batch note")

    visit badge_batch_path(batch)
    click_link I18n.t("badges.buttons.edit_batch")

    batch_edit_title = I18n.t("badges.titles.edit_batch", id: batch.id)
    expect(page).to have_content(batch_edit_title)

    fill_in I18n.t("forms.badge_batch.fields.note"), with: "Updated batch note"
    click_button I18n.t("forms.badge_batch.submit_edit")

    expect(page).to have_content(I18n.t("badges.messages.batch_updated"))
    expect(page).to have_content("Updated batch note")
  end

  scenario "regular user cannot access badges" do
    logout
    sign_in(regular_user)

    visit badge_batches_path

    admin_required_msg = I18n.t("forms.session_new.status.admin_required")
    expect(page).to have_content(admin_required_msg)
    expect(current_path).to eq(root_path)
  end

  scenario "clicking batch row navigates to batch details" do
    batch = create(:badge_batch, :with_badges, note: "Row click test")

    visit badge_batches_path

    within("li", text: batch.id.to_s) do
      click_link
    end

    expect(current_path).to eq(badge_batch_path(batch))
    expect(page).to have_content("Row click test")
  end

  scenario "clicking badge row navigates to badge edit" do
    batch = create(:badge_batch)
    badge = create(:badge, badge_batch: batch, note: "Badge row test")

    visit badge_batch_path(batch)

    within("li", text: badge.id) do
      click_link
    end

    expect(current_path).to eq(edit_badge_path(badge))
    expect(page).to have_content(I18n.t("badges.titles.edit", id: badge.id))
  end

  scenario "back button navigates from batch to index" do
    batch = create(:badge_batch)

    visit badge_batch_path(batch)
    click_link I18n.t("badges.buttons.back")

    expect(current_path).to eq(badge_batches_path)
  end

  scenario "displaying batch count in index" do
    batch = create(:badge_batch, count: 25)

    visit badge_batches_path

    within("li", text: batch.id.to_s) do
      expect(page).to have_content("25")
    end
  end

  scenario "viewing all badges in a batch" do
    batch = create(:badge_batch, count: 3)
    badges = create_list(:badge, 3, badge_batch: batch)

    visit badge_batch_path(batch)

    badges.each do |badge|
      expect(page).to have_content(badge.id)
    end
  end
end
