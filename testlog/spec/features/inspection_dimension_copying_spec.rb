require "rails_helper"

RSpec.feature "Inspection Dimension Copying", type: :feature do
  let(:user) { create(:user, :without_company) }
  let(:company) { create(:inspector_company) }
  let!(:unit) { create(:unit, user: user) }

  before do
    user.update(inspection_company: company)
    sign_in(user)
  end

  describe "creating inspection from unit with dimensions" do
    before do
      # Set up unit with various dimensions
      unit.update!(
        width: 12.5,
        length: 10.0,
        height: 4.0,
        num_low_anchors: 6,
        num_high_anchors: 2,
        rope_size: 15.0,
        slide_platform_height: 2.5,
        slide_wall_height: 1.8,
        runout_value: 3.0,
        containing_wall_height: 1.2,
        platform_height: 2.0,
        user_height: 1.8,
        users_at_1000mm: 10,
        users_at_1200mm: 15,
        users_at_1500mm: 20,
        users_at_1800mm: 25,
        play_area_length: 9.5,
        play_area_width: 9.5
      )
    end

    it "copies all dimensions from unit to inspection" do
      visit unit_path(unit)
      click_button I18n.t("units.buttons.add_inspection")

      # Inspection should be created and we should be on edit page
      expect(page).to have_content(I18n.t("inspections.messages.created"))

      # Get the created inspection
      inspection = user.inspections.last

      # Verify basic dimensions were copied
      expect(inspection.width).to eq(12.5)
      expect(inspection.length).to eq(10.0)
      expect(inspection.height).to eq(4.0)

      # Verify anchorage dimensions
      expect(inspection.num_low_anchors).to eq(6)
      expect(inspection.num_high_anchors).to eq(2)

      # Verify other dimensions
      expect(inspection.rope_size).to eq(15.0)
      expect(inspection.slide_platform_height).to eq(2.5)
      expect(inspection.containing_wall_height).to eq(1.2)
      expect(inspection.users_at_1000mm).to eq(10)
    end

    it "pre-fills assessment forms with unit dimensions" do
      visit unit_path(unit)
      click_button I18n.t("units.buttons.add_inspection")

      # Click on User Height tab
      click_link I18n.t("inspections.tabs.user_height")

      # Check that user height assessment fields are pre-filled
      within ".user-height-assessment" do
        expect(find_field(I18n.t("inspections.assessments.user_height.fields.containing_wall_height")).value).to eq("1.2")
        expect(find_field(I18n.t("inspections.assessments.user_height.fields.platform_height")).value).to eq("2.0")
        expect(find_field(I18n.t("inspections.assessments.user_height.fields.user_height")).value).to eq("1.8")
        expect(find_field(I18n.t("inspections.assessments.user_height.fields.users_at_1000mm")).value).to eq("10")
        expect(find_field(I18n.t("inspections.assessments.user_height.fields.play_area_length")).value).to eq("9.5")
        expect(find_field(I18n.t("inspections.assessments.user_height.fields.play_area_width")).value).to eq("9.5")
      end

      # Click on Structure tab
      click_link I18n.t("inspections.tabs.structure")

      # Click on Anchorage tab
      click_link I18n.t("inspections.tabs.anchorage")

      # Check that anchorage assessment fields are pre-filled
      within ".anchorage-assessment" do
        expect(find_field(I18n.t("inspections.assessments.anchorage.fields.num_low_anchors")).value).to eq("6")
        expect(find_field(I18n.t("inspections.assessments.anchorage.fields.num_high_anchors")).value).to eq("2")
      end
    end
  end

  describe "unit dimension updates" do
    let!(:inspection) { create(:inspection, unit: unit, user: user, width: 10, length: 10, height: 3) }

    it "preserves inspection dimensions when unit is updated" do
      # Original inspection dimensions
      expect(inspection.width).to eq(10)
      expect(inspection.length).to eq(10)
      expect(inspection.height).to eq(3)

      # Update unit dimensions
      visit edit_unit_path(unit)
      fill_in "unit_width", with: "15"
      fill_in "unit_length", with: "15"
      fill_in "unit_height", with: "5"
      click_button I18n.t("units.buttons.update")

      # Verify unit was updated
      unit.reload
      expect(unit.width).to eq(15)

      # Verify inspection dimensions remain unchanged
      inspection.reload
      expect(inspection.width).to eq(10)
      expect(inspection.length).to eq(10)
      expect(inspection.height).to eq(3)
    end
  end

  describe "assessment dimension pre-filling for specific unit types" do
    context "with slide unit" do
      before do
        unit.update!(
          has_slide: true,
          slide_platform_height: 3.0,
          slide_wall_height: 2.0,
          runout_value: 4.5,
          slide_first_metre_height: 1.5,
          slide_beyond_first_metre_height: 0.8
        )
      end

      it "pre-fills slide assessment with unit's slide dimensions" do
        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        click_link I18n.t("inspections.tabs.slide")

        # Check that slide dimensions are copied to the assessment
        within ".slide-assessment" do
          expect(find_field(I18n.t("inspections.assessments.slide.fields.slide_platform_height")).value).to eq("3.0")
          expect(find_field(I18n.t("inspections.assessments.slide.fields.slide_wall_height")).value).to eq("2.0")
          expect(find_field(I18n.t("inspections.assessments.slide.fields.runout_value")).value).to eq("4.5")
          expect(find_field(I18n.t("inspections.assessments.slide.fields.slide_first_metre_height")).value).to eq("1.5")
          expect(find_field(I18n.t("inspections.assessments.slide.fields.slide_beyond_first_metre_height")).value).to eq("0.8")
          # Note: slide_permanent_roof doesn't exist on units, only on slide assessments
        end
      end
    end

    context "with totally enclosed unit" do
      before do
        unit.update!(
          is_totally_enclosed: true,
          exit_number: 3
        )
      end

      it "pre-fills enclosed assessment with unit's exit number" do
        visit unit_path(unit)
        click_button I18n.t("units.buttons.add_inspection")

        click_link I18n.t("inspections.tabs.enclosed")

        within ".enclosed-assessment" do
          expect(find_field(I18n.t("inspections.assessments.enclosed.fields.exit_number")).value).to eq("3")
        end
      end
    end
  end
end
