require "rails_helper"

RSpec.feature "Filter Visibility", type: :feature do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "Inspections index page" do
    context "when user has no inspections and no units" do
      it "does not show the filter form" do
        visit inspections_path

        expect(page).not_to have_css("form[action='#{inspections_path}'][method='get']")
        expect(page).not_to have_field("query")
        expect(page).not_to have_select("result")
        expect(page).not_to have_select("unit_id")
      end
    end

    context "when user has units but no inspections" do
      before do
        create(:unit, user: user)
      end

      it "shows the filter form to allow filtering by unit" do
        visit inspections_path

        expect(page).to have_css("form[action='#{inspections_path}'][method='get']")
        expect(page).to have_field("query")
        expect(page).to have_select("result")
        expect(page).to have_select("unit_id")
      end
    end

    context "when user has inspections" do
      before do
        create(:inspection, user: user)
      end

      it "shows the filter form" do
        visit inspections_path

        expect(page).to have_css("form[action='#{inspections_path}'][method='get']")
        expect(page).to have_field("query")
        expect(page).to have_select("result")
      end
    end

    context "when user has both draft and completed inspections" do
      before do
        unit = create(:unit, user: user)
        create(:inspection, :draft, user: user, unit: unit)
        create(:inspection, :completed, user: user, unit: unit)
      end

      it "shows the filter form" do
        visit inspections_path

        expect(page).to have_css("form[action='#{inspections_path}'][method='get']")
        expect(page).to have_field("query")
        expect(page).to have_select("result")
        expect(page).to have_select("unit_id")
      end
    end
  end

  describe "Units index page" do
    context "when user has no units" do
      it "does not show the filter form" do
        visit units_path

        expect(page).not_to have_css("form[action='#{units_path}'][method='get']")
        expect(page).not_to have_field("query")
        expect(page).not_to have_select("status")
        expect(page).not_to have_select("manufacturer")
        expect(page).not_to have_select("owner")
        expect(page).to have_content(I18n.t("units.messages.no_units_found"))
      end
    end

    context "when user has units" do
      before do
        create(:unit, user: user, manufacturer: "Acme Corp", owner: "John Doe")
        create(:unit, user: user, manufacturer: "Widget Inc", owner: "Jane Smith")
      end

      it "shows the filter form" do
        visit units_path

        expect(page).to have_css("form[action='#{units_path}'][method='get']")
        expect(page).to have_field("query")
        expect(page).to have_select("status")
        expect(page).to have_select("manufacturer")
        expect(page).to have_select("owner")
      end

      it "populates manufacturer dropdown with unique values" do
        visit units_path

        within "select[name='manufacturer']" do
          expect(page).to have_content("All Manufacturers")
          expect(page).to have_content("Acme Corp")
          expect(page).to have_content("Widget Inc")
        end
      end

      it "populates owner dropdown with unique values" do
        visit units_path

        within "select[name='owner']" do
          expect(page).to have_content("All Owners")
          expect(page).to have_content("John Doe")
          expect(page).to have_content("Jane Smith")
        end
      end
    end

    context "when filtering results in no units" do
      before do
        create(:unit, user: user, manufacturer: "Acme Corp")
      end

      it "still shows the filter form to allow clearing filters" do
        visit units_path(manufacturer: "NonExistent Corp")

        expect(page).to have_css("form[action='#{units_path}'][method='get']")
        expect(page).to have_content(I18n.t("units.messages.no_units_found"))
        expect(page).to have_link(I18n.t("ui.buttons.clear_filters"))
      end
    end
  end

  describe "Cross-user isolation" do
    before do
      # Other user has units and inspections
      other_unit = create(:unit, user: other_user)
      create(:inspection, user: other_user, unit: other_unit)

      # Current user has nothing
    end

    it "does not show filter form based on other user's data" do
      visit inspections_path
      expect(page).not_to have_css("form[action='#{inspections_path}'][method='get']")

      visit units_path
      expect(page).not_to have_css("form[action='#{units_path}'][method='get']")
    end
  end
end
