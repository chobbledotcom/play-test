require "rails_helper"

RSpec.feature "Inspection UI and Accessibility", type: :feature do
  let(:inspection) { create(:inspection) }
  let(:user) { inspection.user }
  let(:unit) { inspection.unit }

  before do
    login_user_via_form(user)
    visit edit_inspection_path(inspection)
  end

  scenario "displays tabbed interface with all expected elements" do
    within(".inspection-overview") do
      %w[unit_name serial status progress].each do |field|
        expect(page).to have_content(I18n.t("inspections.fields.#{field}"))
      end
    end

    %w[inspection user_height structure anchorage materials fan slide enclosed].each do |tab|
      expect(page).to have_content(I18n.t("forms.#{tab}.header"))
    end

    within("nav.tabs") { expect(page).to have_css("span", text: I18n.t("forms.inspection.header")) }

    click_link I18n.t("forms.user_height.header")
    expect(current_url).to include("tab=user_height")
    within("nav.tabs") { expect(page).to have_css("span", text: I18n.t("forms.user_height.header")) }
  end

  scenario "conditionally shows tabs based on unit configuration" do
    visit edit_inspection_path(create(:inspection, :without_slide, user: user))
    expect(page).not_to have_content(I18n.t("forms.slide.header"))

    visit edit_inspection_path(create(:inspection, :not_totally_enclosed, user: user))
    expect(page).not_to have_content(I18n.t("forms.enclosed.header"))
  end

  scenario "displays form sections with proper content" do
    within_fieldset("forms.inspection.sections.current_unit") do
      expect(page).to have_content(unit.name)
      expect(page).to have_content(unit.serial)
      expect(page).to have_link(I18n.t("inspections.buttons.change_unit"))
    end

    within_fieldset("forms.inspection.sections.public_information") do
      expect(page).to have_content(I18n.t("inspections.fields.id"))
      expect(page).to have_link(I18n.t("inspections.buttons.download_pdf"))
      expect(page).to have_link(I18n.t("inspections.buttons.download_qr_code"))
    end

    expect(page).to have_content(I18n.t("inspections.fields.reinspection_date"))
    expect(page).to have_button(I18n.t("inspections.buttons.delete"))
  end

  scenario "has proper accessibility features" do
    expect(page).to have_css("h1", text: I18n.t("inspections.titles.edit"))
    expect(page).to have_css("h2", text: I18n.t("inspections.headers.overview"))
    expect(page).to have_css("legend", text: I18n.t("forms.inspection.sections.current_unit"))

    %w[inspection_location passed_true passed_false].each do |field_id|
      expect(page).to have_css("label[for*='#{field_id}']")
    end
  end

  scenario "enforces user permissions for unit visibility" do
    create(:unit, user: user, serial: "MINE001")
    create(:unit, user: create(:user), serial: "OTHER001")

    within_fieldset("forms.inspection.sections.current_unit") do
      click_link I18n.t("inspections.buttons.change_unit")
    end

    expect(page).to have_content("MINE001")
    expect(page).not_to have_content("OTHER001")
  end

  private

  def within_fieldset(i18n_key, &block)
    within("fieldset", text: I18n.t(i18n_key), &block)
  end
end
