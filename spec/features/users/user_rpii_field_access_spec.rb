# typed: false

require "rails_helper"

RSpec.feature "User RPII Field Access Control", type: :feature do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :without_company) }

  describe "Admin access" do
    before { sign_in(admin_user) }

    it "can edit RPII field" do
      user = create(:user, rpii_inspector_number: "RPII-123")
      visit edit_user_path(user)

      fill_in_form :user_edit, :rpii_inspector_number, "RPII-456"
      submit_form :user_edit

      expect(user.reload.rpii_inspector_number).to eq("RPII-456")
    end
  end

  describe "Regular user access" do
    before { sign_in(regular_user) }

    it "cannot see RPII field" do
      visit edit_user_path(regular_user)
      expect_field_not_present :user_edit, :rpii_inspector_number
    end

    it "cannot edit others" do
      visit edit_user_path(create(:user))
      expect(page).to have_current_path(root_path)
    end
  end

  it "shows RPII field in registration" do
    visit new_user_path
    expect_field_present :user_new, :rpii_inspector_number
  end
end
