require "rails_helper"

RSpec.feature "Inspections Index Page", type: :feature do
  let(:inspector_company) { create(:inspector_company) }
  let(:user) { create(:user, inspection_company: inspector_company) }
  let(:unit) { create(:unit, user: user) }

  # Helper method to create inspections for the current user
  def create_user_inspection(attributes = {})
    defaults = {
      user: user,
      unit: unit,
      inspector_company: inspector_company
    }
    create(:inspection, defaults.merge(attributes))
  end

  # Helper method to create inspections for other users
  def create_other_user_inspection(other_user, other_unit, attributes = {})
    defaults = {
      user: other_user,
      unit: other_unit,
      inspector_company: inspector_company
    }
    create(:inspection, defaults.merge(attributes))
  end

  before do
    login_user_via_form(user)
  end

  describe "viewing inspections list" do
    context "when user has no inspections" do
      it "displays empty state message" do
        visit inspections_path

        expect(page).to have_content("No inspection records found")
        expect(page).to have_link(I18n.t("inspections.buttons.add_via_units"))
      end
    end

    context "when user has inspections" do
      let!(:inspection) { create_user_inspection(inspection_location: "Test Location") }

      it "displays inspections in the list" do
        visit inspections_path

        expect(page).to have_content(unit.name)
        expect(page).to have_content(unit.serial)
        expect(page).to have_content("Test Location")
      end

      it "shows inspection result" do
        visit inspections_path
        expect(page).to have_content("PASS")
      end

      it "shows inspection date in readable format" do
        visit inspections_path
        # The date should be displayed in a readable format (abbreviated)
        expect(page).to have_content(Date.current.strftime("%b %d, %Y"))
      end

      it "provides link to edit inspection" do
        visit inspections_path
        expect(page).to have_link("Edit")
      end

      it "provides link to view certificate" do
        visit inspections_path
        expect(page).to have_link("Certificate")
      end
    end

    context "when inspection has missing data" do
      let!(:draft_inspection) do
        create_user_inspection(
          inspection_location: "",
          status: "draft"
        )
      end

      it "handles missing location data gracefully" do
        visit inspections_path

        # Should not crash when location fields are blank
        # Check that the inspection appears even without location data
        expect(page).to have_content(unit.name)
      end
    end

    context "when user has multiple inspections" do
      let!(:inspection1) { create_user_inspection(inspection_location: "Location 1") }
      let!(:inspection2) { create_user_inspection(inspection_location: "Location 2") }

      it "displays all user's inspections" do
        visit inspections_path

        expect(page).to have_content("Location 1")
        expect(page).to have_content("Location 2")
      end
    end
  end

  describe "page layout and metadata" do
    let!(:inspection) { create_user_inspection(inspection_location: "Test Location") }

    it "has proper page title" do
      visit inspections_path
      expect(page.title).to include("patlog.co.uk")
    end

    it "has proper heading" do
      visit inspections_path
      expect(page).to have_css("h1", text: I18n.t("inspections.titles.index"))
    end

    it "includes table headers" do
      visit inspections_path
      expect(page).to have_css("th", text: "Name")
      expect(page).to have_css("th", text: "Serial")
    end
  end

  describe "data isolation between users" do
    let(:other_user) { create(:user, inspection_company: inspector_company) }
    let(:other_unit) { create(:unit, user: other_user) }

    let!(:other_inspection) do
      create_other_user_inspection(other_user, other_unit,
        inspection_location: "Other Location")
    end

    let!(:my_inspection) { create_user_inspection(inspection_location: "My Location") }

    it "only shows current user's inspections" do
      visit inspections_path

      expect(page).to have_content("My Location")
      expect(page).not_to have_content("Other Location")
    end
  end
end
