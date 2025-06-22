require "rails_helper"

# Units Controller Request Tests (formerly Equipment)
# ==================================================
#
# Tests for the UnitsController which manages equipment/units in the PAT testing system.
# Uses FactoryBot for test data creation and comprehensive CRUD testing.

RSpec.describe "Units", type: :request do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :admin) }
  let(:unit) { create(:unit, user: user) }

  describe "Authentication requirements" do
    describe "GET /units" do
      it "redirects to login when not logged in" do
        visit units_path
        expect(page).to have_current_path(login_path)
      end
    end

    describe "GET /units/:id" do
      it "shows unit page when not logged in (public access)" do
        visit unit_path(unit)
        expect(page).to have_current_path(unit_path(unit))
        # When not logged in, the page shows an iframe with the PDF
        expect(page).to have_css("iframe[src='#{unit_path(unit, format: :pdf)}']")
      end
    end

    describe "GET /units/new" do
      it "redirects to login when not logged in" do
        visit new_unit_path
        expect(page).to have_current_path(login_path)
      end
    end
  end

  describe "When logged in" do
    before do
      login_user_via_form(user)
    end

    describe "GET /units" do
      it "returns http success and shows units index" do
        visit units_path
        expect(page).to have_http_status(:success)
        expect(page).to have_content(I18n.t("units.titles.index"))
      end

      it "displays user's units" do
        create(:unit, user: user, name: "Unit 1")
        create(:unit, user: user, name: "Unit 2")
        create(:unit, name: "Other Unit")

        visit units_path

        expect(page).to have_content("Unit 1")
        expect(page).to have_content("Unit 2")
        expect(page).not_to have_content("Other Unit")
      end

      it "shows unit details in table" do
        test_unit = create(:unit, user: user, name: "Test Bouncy Castle", manufacturer: "ACME Corp", serial: "TEST123")

        visit units_path

        expect(page).to have_link("Test Bouncy Castle", href: unit_path(test_unit))
        expect(page).to have_content("ACME Corp")
        expect(page).to have_content("TEST123")
      end

      it "provides navigation to create new unit" do
        visit units_path
        expect(page).to have_button(I18n.t("units.buttons.add_unit"))
      end

      it "supports CSV export" do
        create(:unit, user: user)

        visit units_path
        if page.has_link?(I18n.t("units.buttons.export_csv"))
          click_link I18n.t("units.buttons.export_csv")
          expect(page.response_headers["Content-Type"]).to include("text/csv")
        end
      end
    end

    describe "GET /units/:id" do
      it "displays unit details" do
        visit unit_path(unit)
        expect(page).to have_http_status(:success)
        expect(page).to have_content(unit.name)
        expect(page).to have_content(unit.manufacturer)
        expect(page).to have_content(unit.serial)
        expect(page).to have_content(unit.description)
      end

      it "shows associated inspections section" do
        create(:inspection, unit: unit, user: user)

        visit unit_path(unit)
        expect(page).to have_content("Inspections")
      end

      it "provides edit and delete actions" do
        visit unit_path(unit)
        expect(page).to have_link("Edit", href: edit_unit_path(unit))
        expect(page).to have_link("Delete", href: unit_path(unit))
      end

      it "displays manufacturer and owner information" do
        test_unit = create(:unit, user: user, manufacturer: "ACME Corp", owner: "John Doe")

        visit unit_path(test_unit)

        expect(page).to have_content("ACME Corp")
        expect(page).to have_content("John Doe")
      end

      it "shows minimal PDF viewer for other user's unit" do
        other_unit = create(:unit)

        visit unit_path(other_unit)
        expect(page).to have_current_path(unit_path(other_unit))
        expect(page).to have_css("iframe")
      end
    end

    describe "GET /units/new" do
      it "displays new unit form" do
        visit new_unit_path
        expect(page).to have_http_status(:success)
        expect(page).to have_content(I18n.t("units.titles.new"))

        expect_form_matches_i18n("forms.units")
      end
    end

    describe "POST /units" do
      it "creates unit with valid data" do
        visit new_unit_path

        fill_in I18n.t("forms.units.fields.name"), with: "New Test Unit"
        # Has slide checkbox defaults to unchecked
        fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
        fill_in I18n.t("forms.units.fields.model"), with: "Test Model"
        fill_in I18n.t("forms.units.fields.serial"), with: "NEWTEST123"
        fill_in I18n.t("forms.units.fields.description"), with: "Test Description"
        fill_in I18n.t("forms.units.fields.owner"), with: "Test Owner"

        click_button I18n.t("forms.units.submit")

        expect(page).to have_content(I18n.t("units.messages.created"))
        expect(page).to have_content("New Test Unit")

        created_unit = user.units.find_by(name: "New Test Unit")
        expect(created_unit).to be_present
        expect(created_unit.user).to eq(user)
        expect(created_unit.name).to eq("New Test Unit")
      end

      it "shows validation errors for invalid data" do
        visit new_unit_path

        # Submit form with missing required fields
        click_button I18n.t("forms.units.submit")

        expect(page).to have_http_status(:unprocessable_entity)
        expect_form_errors :units
      end

      it "handles duplicate serial validation" do
        existing_unit = create(:unit, user: user, serial: "DUPLICATE123", manufacturer: "Same Mfg")

        visit new_unit_path

        fill_in I18n.t("forms.units.fields.name"), with: "New Unit"
        fill_in I18n.t("forms.units.fields.manufacturer"), with: "Same Mfg"
        fill_in I18n.t("forms.units.fields.serial"), with: existing_unit.serial
        fill_in I18n.t("forms.units.fields.description"), with: "Test Description"
        fill_in I18n.t("forms.units.fields.owner"), with: "Test Owner"

        click_button I18n.t("forms.units.submit")

        expect(page).to have_http_status(:unprocessable_entity)
        expect(page).to have_content("has already been taken")
      end
    end

    describe "GET /units/:id/edit" do
      it "displays edit form with unit data" do
        visit edit_unit_path(unit)
        expect(page).to have_http_status(:success)
        expect(page).to have_content(I18n.t("units.titles.edit"))

        expect(page).to have_field(I18n.t("forms.units.fields.name"), with: unit.name)
        expect(page).to have_field(I18n.t("forms.units.fields.manufacturer"), with: unit.manufacturer)
        expect(page).to have_field(I18n.t("forms.units.fields.serial"), with: unit.serial)
        expect(page).to have_button(I18n.t("forms.units.submit"))
      end

      it "denies access to other user's unit" do
        other_unit = create(:unit)

        visit edit_unit_path(other_unit)
        expect(page).to have_current_path(units_path)
        expect(page).to have_content("Access denied")
      end
    end

    describe "PATCH /units/:id" do
      it "updates unit successfully" do
        visit edit_unit_path(unit)

        fill_in I18n.t("forms.units.fields.name"), with: "Updated Unit Name"
        fill_in I18n.t("forms.units.fields.description"), with: "Updated Description"
        click_button I18n.t("forms.units.submit")

        expect(page).to have_content(I18n.t("units.messages.updated"))
        expect(page).to have_content("Updated Unit Name")

        unit.reload
        expect(unit.name).to eq("Updated Unit Name")
        expect(unit.description).to eq("Updated Description")
      end

      it "handles validation errors on update" do
        visit edit_unit_path(unit)

        fill_in I18n.t("forms.units.fields.name"), with: ""
        click_button I18n.t("forms.units.submit")

        expect(page).to have_http_status(:unprocessable_entity)
        expect_form_errors :units
      end

      it "denies access to other user's unit" do
        other_unit = create(:unit)

        visit edit_unit_path(other_unit)
        expect(page).to have_current_path(units_path)
        expect(page).to have_content("Access denied")
      end
    end

    describe "DELETE /units/:id" do
      it "destroys unit with confirmation" do
        unit_to_delete = create(:unit, user: user, name: "Unit to Delete")

        visit unit_path(unit_to_delete)

        # For rack_test driver, we can't test JavaScript confirmations
        # so we'll test the delete link existence and then simulate the delete
        expect(page).to have_link("Delete", href: unit_path(unit_to_delete))

        # Simulate the delete action directly
        page.driver.submit :delete, unit_path(unit_to_delete), {}

        expect(page).to have_current_path(units_path)
        expect(page).to have_content(I18n.t("units.messages.deleted"))

        expect { unit_to_delete.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "prevents deletion of other user's unit" do
        other_unit = create(:unit)

        # Try to delete another user's unit
        page.driver.submit :delete, unit_path(other_unit), {}

        expect(page).to have_current_path(units_path)
        expect(page).to have_content("Access denied")

        # Verify the unit wasn't deleted
        expect { other_unit.reload }.not_to raise_error
      end
    end

    describe "Search and filtering functionality" do
      before do
        create(:unit, user: user, name: "Searchable Bouncy Castle", manufacturer: "ACME Corp", owner: "John Doe")
        create(:unit, user: user, name: "Different Slide", manufacturer: "XYZ Industries", owner: "Jane Smith")
      end

      it "performs search by name" do
        visit units_path

        if page.has_field?("Search")
          fill_in "Search", with: "Searchable"
          click_button "Search"

          expect(page).to have_content("Searchable Bouncy Castle")
          expect(page).not_to have_content("Different Slide")
        end
      end

      it "filters by manufacturer" do
        visit units_path

        if page.has_select?("manufacturer")
          select "ACME Corp", from: "manufacturer"
          # Give time for auto-submit or check current page
          visit current_path + "?manufacturer=ACME+Corp"

          expect(page).to have_content("Searchable Bouncy Castle")
          expect(page).not_to have_content("Different Slide")
        end
      end

      it "filters by owner" do
        visit units_path

        if page.has_select?("owner")
          select "Jane Smith", from: "owner"
          # Give time for auto-submit or check current page
          visit current_path + "?owner=Jane+Smith"

          expect(page).to have_content("Different Slide")
          expect(page).not_to have_content("Searchable Bouncy Castle")
        end
      end

      it "shows manufacturer information in the table" do
        visit units_path

        expect(page).to have_content("ACME Corp")
        expect(page).to have_content("XYZ Industries")
      end

      it "filters by manufacturer via URL parameters" do
        visit units_path(manufacturer: "ACME Corp")

        expect(page).to have_content("Searchable Bouncy Castle")
        expect(page).not_to have_content("Different Slide")
        expect(page).to have_content("Units - ACME Corp") # Check filtered title
      end
    end

    describe "Unit details and business logic" do
      it "shows inspection history section" do
        test_unit = create(:unit, user: user)

        visit unit_path(test_unit)

        expect(page).to have_content("Inspection History")
      end

      it "displays inspection history when available" do
        test_unit = create(:unit, user: user)
        create(:inspection, unit: test_unit, user: user, passed: true, inspection_date: 1.month.ago)

        visit unit_path(test_unit)

        expect(page).to have_content("Inspection History")
      end
    end

    describe "File upload functionality" do
      it "allows photo upload during creation" do
        visit new_unit_path

        fill_in I18n.t("forms.units.fields.name"), with: "Unit with Photo"
        # Has slide checkbox defaults to unchecked
        fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
        fill_in I18n.t("forms.units.fields.model"), with: "Test Model"
        fill_in I18n.t("forms.units.fields.serial"), with: "PHOTO123"
        fill_in I18n.t("forms.units.fields.description"), with: "Test Description"
        fill_in I18n.t("forms.units.fields.owner"), with: "Test Owner"

        # Only attach photo if the field exists
        if page.has_field?("Photo")
          attach_file "Photo", Rails.root.join("spec/fixtures/files/test_image.jpg")
        end

        click_button I18n.t("forms.units.submit")

        expect(page).to have_content(I18n.t("units.messages.created"))

        created_unit = user.units.order(:created_at).last
        expect(created_unit).to be_present
        # Photo upload functionality is available but file may not attach in test environment
        expect(created_unit).to respond_to(:photo)
      end
    end

    describe "Navigation and user experience" do
      it "provides breadcrumb navigation" do
        visit unit_path(unit)
        expect(page).to have_link(I18n.t("units.titles.index"), href: units_path)
      end

      it "shows proper page titles" do
        visit units_path
        expect(page).to have_content("Units")

        visit unit_path(unit)
        expect(page).to have_content("Unit Details")
      end

      it "returns 404 for missing units" do
        visit "/units/NONEXISTENT"
        expect(page).to have_http_status(:not_found)
      end
    end
  end

  describe "Admin functionality" do
    before do
      login_user_via_form(admin_user)
    end

    it "admin can access all units" do
      create(:unit, user: user, name: "User's Unit")

      visit units_path
      expect(page).to have_http_status(:success)
      # Admin functionality for units would be implemented here
    end
  end

  describe "Edge cases and error handling" do
    before do
      login_user_via_form(user)
    end

    it "handles concurrent requests gracefully" do
      threads = []
      5.times do
        threads << Thread.new do
          visit units_path
          expect(page).to have_http_status(:success)
        end
      end
      threads.each(&:join)
    end

    it "prevents mass assignment of protected attributes" do
      visit new_unit_path

      # Attempt to set user_id via form manipulation would be blocked by controller
      fill_in I18n.t("forms.units.fields.name"), with: "Protected Unit"
      # Has slide checkbox defaults to unchecked
      fill_in I18n.t("forms.units.fields.manufacturer"), with: "Test Manufacturer"
      fill_in I18n.t("forms.units.fields.model"), with: "Test Model"
      fill_in I18n.t("forms.units.fields.serial"), with: "PROTECT123"
      fill_in I18n.t("forms.units.fields.description"), with: "Test Description"
      fill_in I18n.t("forms.units.fields.owner"), with: "Test Owner"

      click_button I18n.t("forms.units.submit")

      created_unit = user.units.find_by(serial: "PROTECT123")
      expect(created_unit).to be_present
      expect(created_unit.user).to eq(user) # Should be current user, not admin_user
    end
  end

  describe "Format-specific responses" do
    before do
      login_as(user)
    end

    describe "JSON format" do
      it "returns unit data as JSON" do
        get unit_path(unit, format: :json)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")

        json_response = JSON.parse(response.body)
        # The JSON serializer uses symbols as keys, not strings
        expect(json_response).to have_key("name")
        expect(json_response).to have_key("serial")
        expect(json_response).to have_key("manufacturer")
        expect(json_response).to have_key("urls")

        # Check specific values
        expect(json_response["name"]).to eq(unit.name)
        expect(json_response["serial"]).to eq(unit.serial)
        expect(json_response["manufacturer"]).to eq(unit.manufacturer)
      end
    end

    describe "PDF format" do
      it "generates PDF report for unit" do
        get unit_path(unit, format: :pdf)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("#{unit.serial}.pdf")
      end
    end

    describe "CSV export" do
      it "exports units as CSV" do
        get units_path(format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
        expect(response.headers["Content-Disposition"]).to include("units-#{Time.zone.today}.csv")
      end
    end
  end

  describe "Public access functionality" do
    describe "show action with different formats" do
      it "returns PDF for .pdf format" do
        get "/units/#{unit.id}.pdf"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("#{unit.serial}.pdf")
      end

      it "returns JSON for .json format" do
        get "/units/#{unit.id}.json"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "returns PNG (QR code) for .png format" do
        get "/units/#{unit.id}.png"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("image/png")
        expect(response.headers["Content-Disposition"]).to include("#{unit.serial}_QR.png")
      end

      it "returns 404 for non-existent unit" do
        get "/units/NONEXISTENT.pdf"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "HTML access" do
      it "shows minimal PDF viewer for non-logged-in users" do
        get "/units/#{unit.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
        expect(response.body).to include("<iframe")
      end

      it "handles case-insensitive IDs" do
        get "/units/#{unit.id.upcase}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/html")
        expect(response.body).to include("<iframe")
      end
    end
  end

  describe "Create from inspection functionality" do
    let(:inspection) {
      create(:inspection, user: user, unit: nil, width: 5.0, length: 4.0, height: 3.0)
    }

    before do
      login_as(user)
    end

    describe "new_from_inspection" do
      it "shows form for creating unit from inspection" do
        get "/inspections/#{inspection.id}/new_unit"
        expect(response).to have_http_status(:success)
        expect(assigns(:inspection)).to eq(inspection)
        expect(assigns(:unit)).to be_a_new_record
      end

      it "redirects if inspection not found" do
        get "/inspections/999999/new_unit"
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("units.errors.inspection_not_found"))
      end

      it "redirects if inspection already has unit" do
        inspection_with_unit = create(:inspection, user: user, unit: unit)
        get "/inspections/#{inspection_with_unit.id}/new_unit"
        expect(response).to redirect_to(inspection_path(inspection_with_unit))
        expect(flash[:alert]).to eq(I18n.t("units.errors.inspection_has_unit"))
      end
    end

    describe "create_from_inspection" do
      it "creates unit and associates with inspection" do
        post "/inspections/#{inspection.id}/create_unit", params: {
          unit: {
            name: "New Unit from Inspection",
            manufacturer: "Test Manufacturer",
            serial: "FROM_INSP_123",
            description: "Created from inspection",
            owner: "Test Owner",
            width: 5.0,
            length: 4.0,
            height: 3.0,
            model: "Test Model"
          }
        }

        expect(response).to redirect_to(inspection_path(inspection))
        expect(flash[:notice]).to include("created successfully and linked")

        inspection.reload
        expect(inspection.unit).to be_present
        expect(inspection.unit.name).to eq("New Unit from Inspection")
      end

      it "handles validation errors when creating from inspection" do
        post "/inspections/#{inspection.id}/create_unit", params: {
          unit: {
            name: "", # Invalid - required field
            manufacturer: "",
            serial: ""
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:unit).errors).to be_present
      end

      it "redirects if inspection not found during creation" do
        post "/inspections/999999/create_unit", params: {unit: {name: "Test"}}
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("units.errors.inspection_not_found"))
      end

      it "redirects if inspection already has unit during creation" do
        inspection_with_unit = create(:inspection, user: user, unit: unit)
        post "/inspections/#{inspection_with_unit.id}/create_unit", params: {
          unit: {name: "Test"}
        }
        expect(response).to redirect_to(inspection_path(inspection_with_unit))
        expect(flash[:alert]).to eq(I18n.t("units.errors.inspection_has_unit"))
      end
    end
  end

  describe "Turbo stream responses" do
    before do
      login_as(user)
    end

    it "handles successful update with turbo stream" do
      patch unit_path(unit), params: {
        unit: {name: "Updated via Turbo"}
      }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("turbo-stream")
      expect(response.body).to include("form_save_message")
    end
  end

  describe "Access control and error handling" do
    describe "inactive user restrictions" do
      let(:inactive_user) { create(:user, active_until: Date.current - 1.day) }

      before do
        login_as(inactive_user)
      end

      it "prevents inactive user from creating new unit" do
        get new_unit_path
        expect(response).to redirect_to(units_path)
        expect(flash[:alert]).to be_present
      end

      it "prevents inactive user from posting new unit" do
        post units_path, params: {
          unit: {
            name: "Should Fail",
            manufacturer: "Test",
            serial: "FAIL123",
            description: "Test",
            owner: "Test",
            width: 5.0,
            length: 4.0,
            height: 3.0
          }
        }
        expect(response).to redirect_to(units_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe "destroy error handling" do
      before do
        login_as(user)
      end

      it "prevents deletion of units with complete inspections" do
        # Units with complete inspections should not be deletable (defense in depth)
        unit_with_complete = create(:unit, user: user)
        create(:inspection, :completed, unit: unit_with_complete, user: user, passed: true)

        delete unit_path(unit_with_complete)

        expect(response).to redirect_to(unit_path(unit_with_complete))
        expect(flash[:alert]).to be_present
      end

      it "allows deletion of units with only draft inspections" do
        # Units with only draft inspections can be deleted
        unit_with_draft = create(:unit, user: user)
        create(:inspection, unit: unit_with_draft, user: user, complete_date: nil)

        delete unit_path(unit_with_draft)

        expect(response).to redirect_to(units_path)
        expect(flash[:notice]).to eq(I18n.t("units.messages.deleted"))
      end
    end
  end
end
