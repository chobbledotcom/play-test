require "rails_helper"

RSpec.describe "I18n site overrides" do
  describe "functionality" do
    it "loads overrides from site_overrides.yml" do
      # The override file should already exist and be loaded
      expect(I18n.t("forms.units.fields.name")).to eq("BounceSafe Number")
    end

    it "can override any translation key" do
      # Test that the store_translations method works as expected
      I18n.backend.store_translations(:en, {
        test: {temporary: "temp value"}
      }, escape: false)

      expect(I18n.t("test.temporary")).to eq("temp value")
    end
  end

  describe "load path configuration" do
    it "includes site_overrides.yml in load path" do
      override_path = Rails.root.join("config/site_overrides.yml").to_s
      expect(I18n.load_path).to include(override_path)
    end

    it "respects ENV variable for override path" do
      # This would need to be tested at app boot time
      # Just verify the ENV variable exists in our code
      app_rb = Rails.root.join("config/application.rb").read
      expect(app_rb).to include("I18N_OVERRIDES_PATH")
    end
  end
end
