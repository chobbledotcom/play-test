require "rails_helper"

RSpec.feature "Inspection Autosave Locale Keys", type: :feature do
  let(:user) { create(:user) }
  let(:inspection) { create(:inspection, user: user) }

  before do
    sign_in(user)
  end

  scenario "renders autosave status with proper locale keys" do
    # Create an assessment to ensure we have a form to work with
    inspection.create_user_height_assessment!

    visit edit_inspection_path(inspection, tab: "user_height")

    # Check that the autosave status div is present with all locale keys
    autosave_status = find("[data-autosave-status]", visible: :all)

    # Check that all three locale keys are rendered in the HTML (including hidden content)
    expect(autosave_status.text(:all)).to include(I18n.t("autosave.saving"))
    expect(autosave_status.text(:all)).to include(I18n.t("autosave.saved"))
    expect(autosave_status.text(:all)).to include(I18n.t("autosave.error"))

    # Also check the raw HTML to ensure the keys are actually there
    expect(page.html).to include(I18n.t("autosave.saving"))
    expect(page.html).to include(I18n.t("autosave.saved"))
    expect(page.html).to include(I18n.t("autosave.error"))
  end

  scenario "includes autosave status in all assessment forms" do
    # Create all assessments
    inspection.create_user_height_assessment!
    inspection.create_slide_assessment!
    inspection.create_structure_assessment!
    inspection.create_materials_assessment!
    inspection.create_anchorage_assessment!
    inspection.create_fan_assessment!
    inspection.create_enclosed_assessment!

    # Check each tab has the autosave status
    %w[user_height slide structure materials anchorage fan enclosed].each do |tab|
      visit edit_inspection_path(inspection, tab: tab)

      expect(page).to have_css("[data-autosave-status]", visible: :all)
      expect(page).to have_css('form[data-autosave="true"]')

      # Verify the form includes the autosave status partial
      within('form[data-autosave="true"]') do
        expect(page).to have_css("[data-autosave-status]", visible: :all)
      end
    end
  end
end
