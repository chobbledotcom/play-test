require "rails_helper"

RSpec.feature "Admin Text Replacements", type: :feature do
  let(:admin_user) { create(:user, :admin) }

  before do
    sign_in(admin_user)
  end

  scenario "admin can access text replacements from dashboard" do
    visit admin_path
    click_link I18n.t("admin_text_replacements.title")

    expect(page).to have_content(I18n.t("admin_text_replacements.index.title"))
  end

  scenario "displays empty state when no replacements exist" do
    visit admin_text_replacements_path

    expect(page).to have_content(I18n.t("admin_text_replacements.index.empty"))
    expect(page).to have_button(I18n.t("admin_text_replacements.index.add_new"))
  end

  scenario "displays replacements in tree structure" do
    create(:text_replacement,
      i18n_key: "en.forms.test.fields.name",
      value: "Custom Name")
    create(:text_replacement,
      i18n_key: "en.forms.test.fields.email",
      value: "Custom Email")

    visit admin_text_replacements_path

    expect(page).to have_content("en")
    expect(page).to have_content("forms")
    expect(page).to have_content("test")
    expect(page).to have_content("fields")
    expect(page).to have_content("name")
    expect(page).to have_content("email")
    expect(page).to have_content("Custom Name")
    expect(page).to have_content("Custom Email")
  end

  scenario "admin can create a new text replacement" do
    visit admin_text_replacements_path
    click_button I18n.t("admin_text_replacements.index.add_new")

    expect(page).to have_content(I18n.t("forms.admin_text_replacements.header"))

    select "en.admin_text_replacements.title", from: "text_replacement_i18n_key"
    fill_in "text_replacement_value", with: "Custom Text Replacements"
    click_button I18n.t("forms.admin_text_replacements.submit")

    expect(page).to have_content(I18n.t("admin_text_replacements.messages.created"))
    expect(page).to have_current_path(admin_text_replacements_path)
    expect(page).to have_content("Custom Text Replacements")
  end

  scenario "admin can delete a text replacement", js: true do
    replacement = create(:text_replacement,
      i18n_key: "en.test.key",
      value: "Test Value")

    visit admin_text_replacements_path

    expect(page).to have_content("Test Value")

    accept_confirm do
      click_button I18n.t("admin_text_replacements.buttons.delete")
    end

    expect(page).to have_content(I18n.t("admin_text_replacements.messages.destroyed"))
    expect(page).not_to have_content("Test Value")
  end

  context "non-admin user" do
    let(:non_admin_user) { create(:user) }

    before do
      sign_in(non_admin_user)
    end

    scenario "requires admin access" do
      visit admin_text_replacements_path

      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("forms.session_new.status.admin_required"))
    end
  end

  scenario "validation errors are displayed" do
    visit new_admin_text_replacement_path

    click_button I18n.t("forms.admin_text_replacements.submit")

    expect(page).to have_content("can't be blank")
  end
end
