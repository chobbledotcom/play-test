require "rails_helper"

RSpec.feature "Safety Standards with Turbo", js: true do
  before { visit safety_standards_path }

  describe "anchor calculator" do
    it "updates results without page reload via Turbo" do
      within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
        fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: 5.0
        fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: 5.0
        fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: 3.0
        click_button I18n.t("forms.safety_standards_anchors.submit")
      end
      
      within("#anchors-result") do
        expect(page).to have_content("8")
        expect(page).to have_content("Total anchors")
      end
      
      expect(page).to have_current_path(safety_standards_path)
    end
    
    it "maintains form values after submission" do
      within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
        fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: 5.0
        fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: 5.0
        fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: 3.0
        click_button I18n.t("forms.safety_standards_anchors.submit")
      end
      
      within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
        expect(find_field(I18n.t("forms.safety_standards_anchors.fields.length")).value).to eq("5.0")
        expect(find_field(I18n.t("forms.safety_standards_anchors.fields.width")).value).to eq("5.0")
        expect(find_field(I18n.t("forms.safety_standards_anchors.fields.height")).value).to eq("3.0")
      end
    end
  end
  
  describe "user capacity calculator" do
    it "updates results without page reload via Turbo" do
      within(".calculator-form", text: I18n.t("forms.safety_standards_user_capacity.header")) do
        fill_in I18n.t("forms.safety_standards_user_capacity.fields.length"), with: 5.0
        fill_in I18n.t("forms.safety_standards_user_capacity.fields.width"), with: 4.0
        fill_in I18n.t("forms.safety_standards_user_capacity.fields.negative_adjustment"), with: 2.0
        click_button I18n.t("forms.safety_standards_user_capacity.submit")
      end
      
      within("#user-capacity-result") do
        expect(page).to have_content("Usable Area: 18.0m²")
        expect(page).to have_content("1.2m users:")
      end
      
      expect(page).to have_current_path(safety_standards_path)
    end
  end
  
  describe "slide runout calculator" do
    it "updates results without page reload via Turbo" do
      within(".calculator-form", text: I18n.t("forms.safety_standards_slide_runout.header")) do
        fill_in I18n.t("forms.safety_standards_slide_runout.fields.platform_height"), with: 2.5
        click_button I18n.t("forms.safety_standards_slide_runout.submit")
      end
      
      within("#slide-runout-result") do
        expect(page).to have_content("Required Runout: 1.25m")
      end
      
      expect(page).to have_current_path(safety_standards_path)
    end
  end
  
  describe "wall height calculator" do
    it "updates results without page reload via Turbo" do
      within(".calculator-form", text: I18n.t("forms.safety_standards_wall_height.header")) do
        fill_in I18n.t("forms.safety_standards_wall_height.fields.user_height"), with: 1.5
        click_button I18n.t("forms.safety_standards_wall_height.submit")
      end
      
      within("#wall-height-result") do
        expect(page).to have_content("Walls must be at least 1.5m")
      end
      
      expect(page).to have_current_path(safety_standards_path)
    end
  end
  
  describe "multiple form interactions" do
    it "updates each form independently" do
      within(".calculator-form", text: I18n.t("forms.safety_standards_anchors.header")) do
        fill_in I18n.t("forms.safety_standards_anchors.fields.length"), with: 5.0
        fill_in I18n.t("forms.safety_standards_anchors.fields.width"), with: 5.0
        fill_in I18n.t("forms.safety_standards_anchors.fields.height"), with: 3.0
        click_button I18n.t("forms.safety_standards_anchors.submit")
      end
      
      within("#anchors-result") do
        expect(page).to have_content("8")
      end
      
      within(".calculator-form", text: I18n.t("forms.safety_standards_user_capacity.header")) do
        fill_in I18n.t("forms.safety_standards_user_capacity.fields.length"), with: 5.0
        fill_in I18n.t("forms.safety_standards_user_capacity.fields.width"), with: 4.0
        fill_in I18n.t("forms.safety_standards_user_capacity.fields.negative_adjustment"), with: 2.0
        click_button I18n.t("forms.safety_standards_user_capacity.submit")
      end
      
      within("#user-capacity-result") do
        expect(page).to have_content("Usable Area: 18.0m²")
      end
      
      within("#anchors-result") do
        expect(page).to have_content("8")
      end
    end
  end
end