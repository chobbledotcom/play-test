# typed: false

require "rails_helper"

RSpec.feature "Safety Standards with Turbo", js: true do
  before { visit safety_standards_path }

  describe "anchor calculator" do
    it "updates results without page reload via Turbo" do
      fill_anchor_calculator(length: 5.0, width: 5.0, height: 3.0)
      expect_anchor_result_header(8)
      expect(page).to have_current_path(safety_standards_path)
    end

    it "maintains form values after submission" do
      fill_anchor_calculator(length: 5.0, width: 5.0, height: 3.0)
      within_form("safety_standards_anchors") do
        form = "safety_standards_anchors"
        expect(find_form_field(form, "length").value).to eq("5.0")
        expect(find_form_field(form, "width").value).to eq("5.0")
        expect(find_form_field(form, "height").value).to eq("3.0")
      end
    end
  end

  describe "slide runout calculator" do
    it "updates results without page reload via Turbo" do
      navigate_to_standard_tab(:slides)
      fill_slide_calculator(platform_height: 2.5)
      within_result(:runout) do
        content = "Base runout: Maximum of 1.25m and 0.3m = 1.25m"
        expect(page).to have_content(content)
      end
      expect(page).to have_current_path(safety_standards_path)
    end
  end

  describe "wall height calculator" do
    it "updates results without page reload via Turbo" do
      navigate_to_standard_tab(:slides)
      fill_wall_height_calculator(platform_height: 2.0, user_height: 1.5)
      within_result(:wall_height) do
        expect(page).to have_content("0.6m - 3.0m")
        expect(page).to have_content("1.5m (user height)")
      end
      expect(page).to have_current_path(safety_standards_path)
    end
  end

  describe "multiple form interactions" do
    it "updates each form independently" do
      fill_anchor_calculator(length: 5.0, width: 5.0, height: 3.0)
      expect_anchor_result_header

      navigate_to_standard_tab(:slides)
      fill_slide_calculator(platform_height: 2.5)
      within_result(:runout) do
        expect(page).to have_content("1.25m")
      end

      navigate_to_standard_tab(:anchorage)
      expect_anchor_result_header
    end
  end
end
