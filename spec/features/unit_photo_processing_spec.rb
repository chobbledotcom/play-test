require "rails_helper"

RSpec.feature "Unit Photo Processing", type: :feature do
  let(:user) { create(:user) }
  let!(:company) { user.inspection_company }

  before do
    sign_in(user)
  end

  scenario "creates unit successfully through web interface" do
    visit new_unit_path

    # Fill in required unit fields
    fill_in I18n.t("units.forms.name"), with: "Test Bouncy Castle"
    fill_in I18n.t("units.forms.serial"), with: "TEST123"
    fill_in I18n.t("units.forms.manufacturer"), with: "Test Manufacturer"
    fill_in I18n.t("units.forms.description"), with: "Test Description"
    fill_in I18n.t("units.forms.owner"), with: "Test Owner"
    fill_in I18n.t("units.forms.width"), with: "10"
    fill_in I18n.t("units.forms.length"), with: "12"
    fill_in I18n.t("units.forms.height"), with: "8"

    click_button I18n.t("units.buttons.create")

    expect(page).to have_content(I18n.t("units.messages.created"))

    # Verify the unit was created with correct data
    unit = Unit.find_by(serial: "TEST123")
    expect(unit).to be_present
    expect(unit.name).to eq("Test Bouncy Castle")
    expect(unit.serial).to eq("TEST123")
    expect(unit.width).to eq(10.0)
    expect(unit.length).to eq(12.0)
    expect(unit.height).to eq(8.0)
  end

  scenario "creates unit with different configurations" do
    visit new_unit_path

    # Fill in required unit fields
    fill_in I18n.t("units.forms.name"), with: "Test Unit with Slide"
    fill_in I18n.t("units.forms.serial"), with: "SLIDE123"
    fill_in I18n.t("units.forms.manufacturer"), with: "Test Manufacturer"
    fill_in I18n.t("units.forms.description"), with: "Test Description"
    fill_in I18n.t("units.forms.owner"), with: "Test Owner"
    fill_in I18n.t("units.forms.width"), with: "15"
    fill_in I18n.t("units.forms.length"), with: "20"
    fill_in I18n.t("units.forms.height"), with: "5"

    # Check the has_slide checkbox
    check I18n.t("units.forms.has_slide")

    click_button I18n.t("units.buttons.create")

    expect(page).to have_content(I18n.t("units.messages.created"))

    # Verify the unit was created with correct configuration
    unit = Unit.find_by(serial: "SLIDE123")
    expect(unit).to be_present
    expect(unit.name).to eq("Test Unit with Slide")
    expect(unit.has_slide).to be true
    expect(unit.width).to eq(15.0)
    expect(unit.length).to eq(20.0)
    expect(unit.height).to eq(5.0)
  end

  scenario "validates required fields in web form" do
    visit new_unit_path

    initial_count = Unit.count

    # Try to create unit without filling required fields
    click_button I18n.t("units.buttons.create")

    # Should show validation errors
    expect(page).to have_content("can't be blank")

    # No new unit should be created
    expect(Unit.count).to eq(initial_count)
  end
end
