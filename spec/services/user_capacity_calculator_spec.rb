require "rails_helper"

RSpec.describe SafetyStandards::UserCapacityCalculator do
  describe ".calculate" do
    context "with valid dimensions" do
      it "calculates correct capacity for each height category" do
        # 10m x 10m = 100m² area
        result = described_class.calculate(10, 10)

        expect(result[:users_1000mm]).to eq(100)  # 100 ÷ 1.0 = 100
        expect(result[:users_1200mm]).to eq(75)   # 100 ÷ 1.33 = 75.18 → 75
        expect(result[:users_1500mm]).to eq(60)   # 100 ÷ 1.66 = 60.24 → 60
        expect(result[:users_1800mm]).to eq(50)   # 100 ÷ 2.0 = 50
      end

      it "rounds down fractional users" do
        # 5m x 5m = 25m² area
        result = described_class.calculate(5, 5)

        expect(result[:users_1000mm]).to eq(25)  # 25 ÷ 1.0 = 25
        expect(result[:users_1200mm]).to eq(18)  # 25 ÷ 1.33 = 18.79 → 18
        expect(result[:users_1500mm]).to eq(15)  # 25 ÷ 1.66 = 15.06 → 15
        expect(result[:users_1800mm]).to eq(12)  # 25 ÷ 2.0 = 12.5 → 12
      end
    end

    context "with maximum user height restriction" do
      it "only calculates capacity for allowed heights" do
        result = described_class.calculate(10, 10, 1.2)

        expect(result[:users_1000mm]).to eq(100)  # Allowed
        expect(result[:users_1200mm]).to eq(75)   # Allowed
        expect(result[:users_1500mm]).to eq(0)    # Not allowed (1.5 > 1.2)
        expect(result[:users_1800mm]).to eq(0)    # Not allowed (1.8 > 1.2)
      end

      it "calculates all heights when max_user_height is nil" do
        result = described_class.calculate(10, 10, nil)

        expect(result[:users_1000mm]).to eq(100)
        expect(result[:users_1200mm]).to eq(75)
        expect(result[:users_1500mm]).to eq(60)
        expect(result[:users_1800mm]).to eq(50)
      end
    end

    context "with invalid dimensions" do
      it "returns default capacity when length is nil" do
        result = described_class.calculate(nil, 10)

        expect(result).to eq({
          users_1000mm: 0,
          users_1200mm: 0,
          users_1500mm: 0,
          users_1800mm: 0
        })
      end

      it "returns default capacity when width is nil" do
        result = described_class.calculate(10, nil)

        expect(result).to eq({
          users_1000mm: 0,
          users_1200mm: 0,
          users_1500mm: 0,
          users_1800mm: 0
        })
      end
    end
  end
end
