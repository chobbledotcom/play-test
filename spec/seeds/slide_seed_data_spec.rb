require "rails_helper"
require Rails.root.join("db/seeds/seed_data")

RSpec.describe "SeedData slide_fields" do
  describe ".slide_fields" do
    context "when passed: true" do
      it "generates runout values that meet safety requirements" do
        10.times do
          fields = SeedData.slide_fields(passed: true)
          platform_height = fields[:slide_platform_height]
          runout = fields[:runout]

          meets_requirements = SafetyStandards::SlideCalculator.meets_runout_requirements?(runout, platform_height)
          required_runout = SafetyStandards::SlideCalculator.calculate_required_runout(platform_height)

          expect(meets_requirements).to be(true),
            "Expected runout #{runout}m to meet requirements for platform height #{platform_height}m (required: #{required_runout}m)"
        end
      end
    end

    context "when passed: false" do
      it "generates runout values that fail safety requirements" do
        10.times do
          fields = SeedData.slide_fields(passed: false)
          platform_height = fields[:slide_platform_height]
          runout = fields[:runout]

          meets_requirements = SafetyStandards::SlideCalculator.meets_runout_requirements?(runout, platform_height)
          required_runout = SafetyStandards::SlideCalculator.calculate_required_runout(platform_height)

          expect(meets_requirements).to be(false),
            "Expected runout #{runout}m to fail requirements for platform height #{platform_height}m (required: #{required_runout}m)"
        end
      end
    end
  end
end
