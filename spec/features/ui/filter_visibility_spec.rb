require "rails_helper"

RSpec.feature "Filter Visibility", type: :feature do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "inspections index page" do
    context "when user has no inspections and no units" do
      scenario "does not show filter form" do
        visit inspections_path

        expect_no_filter_form_for_inspections
      end
    end

    context "when user has units but no inspections" do
      before do
        create(:unit, user: user)
      end

      scenario "shows filter form to allow filtering by unit" do
        visit inspections_path

        expect_inspections_filter_form_present
      end
    end

    context "when user has inspections" do
      before do
        create(:inspection, user: user)
      end

      scenario "shows filter form" do
        visit inspections_path

        expect_inspections_filter_form_present
      end
    end

    context "when user has both draft and completed inspections" do
      before do
        unit = create(:unit, user: user)
        create(:inspection, :draft, user: user, unit: unit)
        create(:inspection, :completed, user: user, unit: unit)
      end

      scenario "shows filter form with unit selector" do
        visit inspections_path

        expect_inspections_filter_form_present
        expect(page).to have_select("unit_id")
      end
    end
  end

  describe "units index page" do
    context "when user has no units" do
      scenario "does not show filter form" do
        visit units_path

        expect_no_filter_form_for_units
        expect(page).to have_content(I18n.t("units.messages.no_units_found"))
      end
    end

    context "when user has units" do
      before do
        create(:unit, user: user, manufacturer: "Acme Corp", operator: "John Doe")
        create(:unit, user: user, manufacturer: "Widget Inc", operator: "Jane Smith")
      end

      scenario "shows filter form" do
        visit units_path

        expect_units_filter_form_present
      end

      scenario "populates manufacturer dropdown with unique values" do
        visit units_path

        expect_manufacturer_dropdown_populated
      end

      scenario "populates operator dropdown with unique values" do
        visit units_path

        expect_operator_dropdown_populated
      end
    end

    context "when filtering results in no units" do
      before do
        create(:unit, user: user, manufacturer: "Acme Corp")
      end

      scenario "shows filter form to allow clearing filters" do
        visit units_path(manufacturer: "NonExistent Corp")

        expect_units_filter_form_present
        expect(page).to have_content(I18n.t("units.messages.no_units_found"))
        expect(page).to have_link(I18n.t("ui.buttons.clear_filters"))

        click_link I18n.t("ui.buttons.clear_filters")

        expect(current_path).to eq(units_path)
        expect(page).not_to have_content(I18n.t("units.messages.no_units_found"))
      end
    end
  end

  describe "cross-user isolation" do
    before do
      other_unit = create(:unit, user: other_user)
      create(:inspection, user: other_user, unit: other_unit)
    end

    scenario "does not show filter form based on other user's data" do
      visit inspections_path
      expect_no_filter_form_for_inspections

      visit units_path
      expect_no_filter_form_for_units
    end
  end

  private

  def expect_no_filter_form_for_inspections
    expect(page).not_to have_css("form[action='#{inspections_path}'][method='get']")
    expect(page).not_to have_field("query")
    expect(page).not_to have_select("result")
    expect(page).not_to have_select("unit_id")
  end

  def expect_inspections_filter_form_present
    expect(page).to have_css("form[action='#{inspections_path}'][method='get']")
    expect(page).to have_field("query")
    expect(page).to have_select("result")
  end

  def expect_no_filter_form_for_units
    expect(page).not_to have_css("form[action='#{units_path}'][method='get']")
    expect(page).not_to have_field("query")
    expect(page).not_to have_select("status")
    expect(page).not_to have_select("manufacturer")
    expect(page).not_to have_select("operator")
  end

  def expect_units_filter_form_present
    expect(page).to have_css("form[action='#{units_path}'][method='get']")
    expect(page).to have_field("query")
    expect(page).to have_select("status")
    expect(page).to have_select("manufacturer")
    expect(page).to have_select("operator")
  end

  def expect_manufacturer_dropdown_populated
    within "select[name='manufacturer']" do
      expect(page).to have_content("All Manufacturers")
      expect(page).to have_content("Acme Corp")
      expect(page).to have_content("Widget Inc")
    end
  end

  def expect_operator_dropdown_populated
    within "select[name='operator']" do
      expect(page).to have_content("All Operators")
      expect(page).to have_content("John Doe")
      expect(page).to have_content("Jane Smith")
    end
  end
end
