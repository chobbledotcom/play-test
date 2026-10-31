# typed: false

require "rails_helper"

RSpec.feature "Inspection edit N/A label", type: :feature do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }
  let(:inspection) { create(:inspection, user: user, unit: unit) }

  background { sign_in(user) }

  scenario "the N/A option is labelled N/A on an assessment tab" do
    visit edit_inspection_path(inspection, tab: "structure")

    field_label = I18n.t("forms.structure.fields.grounding")
    within(:xpath,
      "//div[contains(@class, 'form-grid')]" \
      "[.//label[@class='label'][normalize-space(.)='#{field_label}']]") do
      expect(page).to have_selector("label", text: /\AN\/A\z/)
      expect(page).not_to have_selector("label", text: /\ANot Applicable\z/)
    end

    expect(page).not_to have_content("Not Applicable")
  end

  scenario "no tab of the edit page shows Not Applicable" do
    # Derived from the model's tab registry so a new assessment tab is
    # covered automatically
    inspection.applicable_tabs.each do |tab|
      visit edit_inspection_path(inspection, tab: tab)
      expect(page).not_to have_content("Not Applicable")
    end
  end
end
