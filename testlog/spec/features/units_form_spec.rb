require "rails_helper"

RSpec.describe "Units Form", type: :feature do
  let(:user) { create(:user) }

  before do
    # Login user for form access
    sign_in(user)
  end

  describe "Creating a new unit" do
    before do
      visit "/units/new"
    end

    it "displays all required form fields" do
      expect(page).to have_content(I18n.t("units.headers.unit_details"))

      # Required fields
      expect(page).to have_field(I18n.t("units.forms.name"), type: "text")
      expect(page).to have_field(I18n.t("units.forms.unit_type"))
      expect(page).to have_field(I18n.t("units.forms.manufacturer"), type: "text")
      expect(page).to have_field(I18n.t("units.forms.serial"), type: "text")
      expect(page).to have_field(I18n.t("units.forms.description"))
      expect(page).to have_field(I18n.t("units.forms.owner"), type: "text")

      # Dimension fields
      expect(page).to have_content(I18n.t("units.headers.dimensions"))
      expect(page).to have_field(I18n.t("units.forms.width"), type: "number")
      expect(page).to have_field(I18n.t("units.forms.length"), type: "number")
      expect(page).to have_field(I18n.t("units.forms.height"), type: "number")

      # Optional fields
      expect(page).to have_field(I18n.t("units.forms.model"), type: "text")
      expect(page).to have_field(I18n.t("units.forms.manufacture_date"), type: "date")
      expect(page).to have_field(I18n.t("units.forms.notes"))

      expect(page).to have_button(I18n.t("units.buttons.create"))
    end

    it "has correct unit type options" do
      expect(page).to have_select(I18n.t("units.forms.unit_type"), options: [
        I18n.t("units.unit_types.select_prompt"),
        I18n.t("units.unit_types.bounce_house"),
        I18n.t("units.unit_types.slide"),
        I18n.t("units.unit_types.combo_unit"),
        I18n.t("units.unit_types.obstacle_course"),
        I18n.t("units.unit_types.totally_enclosed")
      ])
    end

    it "successfully creates a unit with valid data" do
      fill_in I18n.t("units.forms.name"), with: "Test Bounce House"
      select I18n.t("units.unit_types.bounce_house"), from: I18n.t("units.forms.unit_type")
      fill_in I18n.t("units.forms.manufacturer"), with: "JumpCo"
      fill_in I18n.t("units.forms.model"), with: "JC-2000"
      fill_in I18n.t("units.forms.serial"), with: "ASSET-001"
      fill_in I18n.t("units.forms.description"), with: "Large bounce house for events"
      fill_in I18n.t("units.forms.owner"), with: "Test Company Ltd"
      fill_in I18n.t("units.forms.width"), with: "5.0"
      fill_in I18n.t("units.forms.length"), with: "5.0"
      fill_in I18n.t("units.forms.height"), with: "3.0"
      fill_in I18n.t("units.forms.manufacture_date"), with: "2023-01-15"
      fill_in I18n.t("units.forms.notes"), with: "Recently purchased, excellent condition"

      click_button I18n.t("units.buttons.create")

      expect(page).to have_current_path(%r{/units/\w+})
      expect(page).to have_content("Test Bounce House")
      expect(page).to have_content("JumpCo")
    end

    it "shows validation errors for missing required fields" do
      click_button I18n.t("units.buttons.create")

      expect(page).to have_content(I18n.t("units.validations.save_error"))
      expect(page).to have_content(I18n.t("units.validations.name_blank"))
      expect(page).to have_content(I18n.t("units.validations.unit_type_blank"))
      expect(page).to have_content(I18n.t("units.validations.manufacturer_blank"))
      expect(page).to have_content(I18n.t("units.validations.serial_blank"))
      expect(page).to have_content(I18n.t("units.validations.description_blank"))
      expect(page).to have_content(I18n.t("units.validations.owner_blank"))
      expect(page).to have_content(I18n.t("units.validations.width_blank"))
      expect(page).to have_content(I18n.t("units.validations.length_blank"))
      expect(page).to have_content(I18n.t("units.validations.height_blank"))
    end

    it "validates dimension fields are numeric and within range" do
      fill_in I18n.t("units.forms.name"), with: "Test Unit"
      select I18n.t("units.unit_types.bounce_house"), from: I18n.t("units.forms.unit_type")
      fill_in I18n.t("units.forms.manufacturer"), with: "Test Mfg"
      fill_in I18n.t("units.forms.serial"), with: "TEST-001"
      fill_in I18n.t("units.forms.description"), with: "Test description"
      fill_in I18n.t("units.forms.owner"), with: "Test Owner"

      # Test invalid dimensions
      fill_in I18n.t("units.forms.width"), with: "0"
      fill_in I18n.t("units.forms.length"), with: "250"
      fill_in I18n.t("units.forms.height"), with: "-1"

      click_button I18n.t("units.buttons.create")

      expect(page).to have_content(I18n.t("units.validations.width_range"))
      expect(page).to have_content(I18n.t("units.validations.length_range"))
      expect(page).to have_content(I18n.t("units.validations.height_range"))
    end

    it "uses correct terminology (Units not Equipment)" do
      expect(page).to have_content(I18n.t("units.headers.unit_details"))
      expect(page).to have_field(I18n.t("units.forms.name"))
      expect(page).to have_button(I18n.t("units.buttons.create"))
      expect(page).not_to have_content("Equipment")
    end
  end

  describe "Editing an existing unit" do
    let(:unit) { create(:unit, user: user, name: "Original Name", unit_type: "bounce_house") }

    before do
      visit edit_unit_path(unit)
    end

    it "populates form with existing unit data" do
      expect(page).to have_field(I18n.t("units.forms.name"), with: unit.name)
      expect(page).to have_select(I18n.t("units.forms.unit_type"), selected: I18n.t("units.unit_types.bounce_house"))
      expect(page).to have_field(I18n.t("units.forms.manufacturer"), with: unit.manufacturer)
      expect(page).to have_button(I18n.t("units.buttons.update"))
    end

    it "successfully updates unit with new data" do
      fill_in I18n.t("units.forms.name"), with: "Updated Name"
      select I18n.t("units.unit_types.slide"), from: I18n.t("units.forms.unit_type")

      click_button I18n.t("units.buttons.update")

      expect(page).to have_current_path(unit_path(unit))
      expect(page).to have_content("Updated Name")
    end

    it "uses correct terminology for updates" do
      expect(page).to have_content(I18n.t("units.headers.unit_details"))
      expect(page).to have_button(I18n.t("units.buttons.update"))
      expect(page).not_to have_content("Equipment")
    end
  end

  describe "Form accessibility and usability" do
    before do
      visit "/units/new"
    end

    it "has proper form structure with fieldset" do
      expect(page).to have_css("fieldset")
      expect(page).to have_css("fieldset header h3", text: I18n.t("units.headers.unit_details"))
      expect(page).to have_css("fieldset header h4", text: I18n.t("units.headers.dimensions"))
    end

    it "has required attributes on mandatory fields" do
      expect(find_field(I18n.t("units.forms.name"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.unit_type"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.manufacturer"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.serial"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.description"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.owner"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.width"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.length"))["required"]).to eq("required")
      expect(find_field(I18n.t("units.forms.height"))["required"]).to eq("required")
    end

    it "has proper input types and constraints on number fields" do
      width_field = find_field(I18n.t("units.forms.width"))
      expect(width_field[:type]).to eq("number")
      expect(width_field[:step]).to eq("0.01")
      expect(width_field[:min]).to eq("0.01")
      expect(width_field[:max]).to eq("199.99")
    end
  end
end
