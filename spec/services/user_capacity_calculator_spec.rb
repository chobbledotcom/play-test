require "rails_helper"

RSpec.describe EN14960::Calculators::UserCapacityCalculator do
  describe ".calculate" do
    context "with valid dimensions" do
      it "returns CalculatorResponse with correct capacity and breakdown" do
        # 10m x 10m = 100m² area
        result = described_class.calculate(10, 10)

        expect(result).to be_a(EN14960::CalculatorResponse)
        capacities = result.value
        expect(capacities[:users_1000mm]).to eq(100)  # 100 ÷ 1.0 = 100
        expect(capacities[:users_1200mm]).to eq(75)   # 100 ÷ 1.33 = 75.18 → 75
        expect(capacities[:users_1500mm]).to eq(60)   # 100 ÷ 1.66 = 60.24 → 60
        expect(capacities[:users_1800mm]).to eq(50)   # 100 ÷ 2.0 = 50

        # Check breakdown structure
        expect(result.breakdown).to include(
          [I18n.t("safety_standards.calculators.user_capacity.total_area"), "10m × 10m = 100m²"],
          [I18n.t("safety_standards.calculators.user_capacity.usable_area"), "100m²"]
        )
      end

      it "rounds down fractional users" do
        # 5m x 5m = 25m² area
        result = described_class.calculate(5, 5)
        capacities = result.value

        expect(capacities[:users_1000mm]).to eq(25)  # 25 ÷ 1.0 = 25
        expect(capacities[:users_1200mm]).to eq(18)  # 25 ÷ 1.33 = 18.79 → 18
        expect(capacities[:users_1500mm]).to eq(15)  # 25 ÷ 1.66 = 15.06 → 15
        expect(capacities[:users_1800mm]).to eq(12)  # 25 ÷ 2.0 = 12.5 → 12
      end
    end

    context "with negative adjustment area" do
      it "subtracts adjustment from total area" do
        # 10m x 10m = 100m², minus 20m² = 80m² usable
        result = described_class.calculate(10, 10, nil, 20)
        capacities = result.value

        expect(capacities[:users_1000mm]).to eq(80)  # 80 ÷ 1.0 = 80
        expect(capacities[:users_1200mm]).to eq(60)  # 80 ÷ 1.33 = 60.15 → 60
        expect(capacities[:users_1500mm]).to eq(48)  # 80 ÷ 1.66 = 48.19 → 48
        expect(capacities[:users_1800mm]).to eq(40)  # 80 ÷ 2.0 = 40

        # Check breakdown includes adjustment
        expect(result.breakdown).to include(
          [I18n.t("safety_standards.calculators.user_capacity.obstacles_adjustments"), "- 20m²"],
          [I18n.t("safety_standards.calculators.user_capacity.usable_area"), "80m²"]
        )
      end

      it "handles adjustment larger than total area" do
        # 5m x 5m = 25m², minus 30m² = 0m² usable
        result = described_class.calculate(5, 5, nil, 30)
        capacities = result.value

        expect(capacities[:users_1000mm]).to eq(0)
        expect(capacities[:users_1200mm]).to eq(0)
        expect(capacities[:users_1500mm]).to eq(0)
        expect(capacities[:users_1800mm]).to eq(0)

        expect(result.breakdown).to include(
          [I18n.t("safety_standards.calculators.user_capacity.usable_area"), "0m²"]
        )
      end

      it "treats negative values as positive adjustments" do
        # Negative adjustment is converted to positive
        result = described_class.calculate(10, 10, nil, -15)
        capacities = result.value

        expect(capacities[:users_1000mm]).to eq(85)  # (100 - 15) ÷ 1.0 = 85
        expect(result.breakdown).to include(
          [I18n.t("safety_standards.calculators.user_capacity.obstacles_adjustments"), "- 15m²"]
        )
      end
    end

    context "with maximum user height restriction" do
      it "only calculates capacity for allowed heights" do
        result = described_class.calculate(10, 10, 1.2)
        capacities = result.value

        expect(capacities[:users_1000mm]).to eq(100)  # Allowed
        expect(capacities[:users_1200mm]).to eq(75)   # Allowed
        expect(capacities[:users_1500mm]).to eq(0)    # Not allowed (1.5 > 1.2)
        expect(capacities[:users_1800mm]).to eq(0)    # Not allowed (1.8 > 1.2)
      end

      it "calculates all heights when max_user_height is nil" do
        result = described_class.calculate(10, 10, nil)
        capacities = result.value

        expect(capacities[:users_1000mm]).to eq(100)
        expect(capacities[:users_1200mm]).to eq(75)
        expect(capacities[:users_1500mm]).to eq(60)
        expect(capacities[:users_1800mm]).to eq(50)
      end
    end

    context "with invalid dimensions" do
      it "returns default result when length is nil" do
        result = described_class.calculate(nil, 10)

        expect(result).to be_a(EN14960::CalculatorResponse)
        expect(result.value).to eq({
          users_1000mm: 0,
          users_1200mm: 0,
          users_1500mm: 0,
          users_1800mm: 0
        })
        expect(result.breakdown).to include(
          ["Invalid dimensions", ""]
        )
      end

      it "returns default result when width is nil" do
        result = described_class.calculate(10, nil)

        expect(result).to be_a(EN14960::CalculatorResponse)
        expect(result.value).to eq({
          users_1000mm: 0,
          users_1200mm: 0,
          users_1500mm: 0,
          users_1800mm: 0
        })
      end
    end
  end
end
