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
        expect(page).to have_button(I18n.t("inspections.buttons.add_inspection"))
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

      it "makes list items clickable and routes to edit for non-complete inspections" do
        visit inspections_path

        # Find the list item containing the inspection data
        inspection_item = page.find("li", text: unit.name)
        inspection_link = inspection_item.find("a.table-list-link")

        # Click the link should navigate to edit page for non-complete inspection
        inspection_link.click
        expect(current_path).to eq(edit_inspection_path(inspection))
      end

      it "routes to view page for complete inspections" do
        # Create a complete inspection
        complete_inspection = create(:inspection, :completed,
          user: user,
          unit: unit,
          inspector_company: inspector_company,
          inspection_location: "Complete Location"
        )

        visit inspections_path

        # Find the list item and click the link
        inspection_item = page.find("li", text: "Complete Location")
        inspection_link = inspection_item.find("a.table-list-link")
        inspection_link.click

        # Should navigate to view page for complete inspection
        expect(current_path).to eq(inspection_path(complete_inspection))
      end
    end

    context "when inspection has missing data" do
      let!(:draft_inspection) do
        create_user_inspection(
          inspection_location: "",
          complete_date: nil
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
      expect(page.title).to include("play-test")
    end

    it "has proper heading" do
      visit inspections_path
      expect(page).to have_css("h1", text: I18n.t("inspections.titles.index"))
    end

    it "includes column headers" do
      visit inspections_path
      # On desktop, headers are visible
      expect(page).to have_css(".table-list-header", text: "Name")
      expect(page).to have_css(".table-list-header", text: "Serial")
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

  describe "creating inspection without unit" do
    it "displays Add Inspection button" do
      visit inspections_path

      expect(page).to have_button(I18n.t("inspections.buttons.add_inspection"))
    end

    it "creates inspection without unit when Add Inspection is clicked" do
      visit inspections_path

      # Note: Capybara's RackTest driver doesn't support JavaScript confirmations
      # In a real browser test, this would show the confirmation dialog
      click_button I18n.t("inspections.buttons.add_inspection")

      # Should redirect to edit page for new inspection
      expect(current_path).to match(/\/inspections\/\w+\/edit/)
      expect(page).to have_content(I18n.t("inspections.messages.created_without_unit"))

      # Verify inspection was created without unit
      inspection = user.inspections.where(unit_id: nil).order(:created_at).last
      expect(inspection).to be_present
      expect(inspection.unit).to be_nil
      expect(inspection.user).to eq(user)
    end
  end

  describe "inspection ordering" do
    context "draft inspections" do
      it "displays oldest draft inspections first" do
        create_user_inspection(
          inspection_location: "Old Draft",
          created_at: 3.days.ago
        )
        create_user_inspection(
          inspection_location: "New Draft",
          created_at: 1.day.ago
        )
        create_user_inspection(
          inspection_location: "Middle Draft",
          created_at: 2.days.ago
        )

        visit inspections_path

        # Find all draft inspection locations in order
        draft_table = page.find("h2", text: "In Progress").sibling(".table-list")
        draft_rows = draft_table.all(".table-list-items li")

        expect(draft_rows[0].text).to include("Old Draft")
        expect(draft_rows[1].text).to include("Middle Draft")
        expect(draft_rows[2].text).to include("New Draft")
      end
    end

    context "completed inspections" do
      it "displays newest completed inspections first" do
        create_user_inspection(
          inspection_location: "Old Complete",
          complete_date: Time.current,
          created_at: 3.days.ago
        )
        create_user_inspection(
          inspection_location: "New Complete",
          complete_date: Time.current,
          created_at: 1.day.ago
        )
        create_user_inspection(
          inspection_location: "Middle Complete",
          complete_date: Time.current,
          created_at: 2.days.ago
        )

        visit inspections_path

        # Find all completed inspection locations in order
        # When there are no draft inspections, the Completed heading isn't shown
        # so we look for the table directly after the filter form
        complete_table = if page.has_css?("h2", text: "Completed")
          page.find("h2", text: "Completed").sibling(".table-list")
        else
          page.find(".table-list")
        end
        complete_rows = complete_table.all(".table-list-items li")

        expect(complete_rows[0].text).to include("New Complete")
        expect(complete_rows[1].text).to include("Middle Complete")
        expect(complete_rows[2].text).to include("Old Complete")
      end
    end
  end
end
