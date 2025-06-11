require "rails_helper"

RSpec.describe HasDimensions, type: :model do
  # Create a test class that includes the concern
  before do
    stub_const("TestModelWithDimensions", Class.new(ApplicationRecord) do
      self.table_name = "units"
      include HasDimensions
    end)
  end

  let(:model) { TestModelWithDimensions.new }

  describe "validations" do
    describe "basic dimensions" do
      it "validates presence of width, length, height when provided" do
        model.width = 0
        model.length = -1
        model.height = 201

        expect(model).not_to be_valid
        expect(model.errors[:width]).to include("must be greater than 0")
        expect(model.errors[:length]).to include("must be greater than 0")
        expect(model.errors[:height]).to include("must be less than 200")
      end

      it "allows nil for optional dimensions" do
        model.width = nil
        model.length = nil
        model.height = nil

        # Should not have errors for nil values
        model.valid?
        expect(model.errors[:width]).to be_empty
        expect(model.errors[:length]).to be_empty
        expect(model.errors[:height]).to be_empty
      end
    end

    describe "integer dimensions" do
      it "validates numericality of anchor counts" do
        model.num_low_anchors = -1
        model.num_high_anchors = "abc"

        expect(model).not_to be_valid
        expect(model.errors[:num_low_anchors]).to include("must be greater than or equal to 0")
        expect(model.errors[:num_high_anchors]).to include("is not a number")
      end

      it "validates user capacity fields" do
        model.users_at_1000mm = -5
        model.users_at_1200mm = 1.5

        expect(model).not_to be_valid
        expect(model.errors[:users_at_1000mm]).to include("must be greater than or equal to 0")
        expect(model.errors[:users_at_1200mm]).to include("must be an integer")
      end
    end

    describe "decimal dimensions" do
      it "validates non-negative decimal fields" do
        model.rope_size = -1
        model.slide_platform_height = -0.5

        expect(model).not_to be_valid
        expect(model.errors[:rope_size]).to include("must be greater than or equal to 0")
        expect(model.errors[:slide_platform_height]).to include("must be greater than or equal to 0")
      end
    end
  end

  describe "instance methods" do
    before do
      model.width = 10
      model.length = 8
      model.height = 3
    end

    describe "#dimensions" do
      it "returns formatted dimensions string" do
        expect(model.dimensions).to eq("10m × 8m × 3m")
      end

      it "returns nil when dimensions are missing" do
        model.width = nil
        expect(model.dimensions).to be_nil
      end
    end

    describe "#area" do
      it "calculates area from width and length" do
        expect(model.area).to eq(80)
      end

      it "returns nil when dimensions are missing" do
        model.width = nil
        expect(model.area).to be_nil
      end
    end

    describe "#volume" do
      it "calculates volume from all dimensions" do
        expect(model.volume).to eq(240)
      end

      it "returns nil when dimensions are missing" do
        model.height = nil
        expect(model.volume).to be_nil
      end
    end

    describe "#dimension_attributes" do
      it "returns a hash of all dimension attributes" do
        model.num_low_anchors = 4
        model.rope_size = 12.5

        attrs = model.dimension_attributes
        expect(attrs[:width]).to eq(10)
        expect(attrs[:length]).to eq(8)
        expect(attrs[:height]).to eq(3)
        expect(attrs[:num_low_anchors]).to eq(4)
        expect(attrs[:rope_size]).to eq(12.5)
      end

      it "compacts nil values" do
        attrs = model.dimension_attributes
        expect(attrs).not_to have_key(:num_low_anchors)
        expect(attrs).not_to have_key(:rope_size)
      end
    end

    describe "#copy_dimensions_from" do
      let(:source) { TestModelWithDimensions.new }

      before do
        source.width = 15
        source.length = 12
        source.height = 4
        source.num_low_anchors = 6
        source.slide_platform_height = 2.5
      end

      it "copies all dimension attributes from another object" do
        model.copy_dimensions_from(source)

        expect(model.width).to eq(15)
        expect(model.length).to eq(12)
        expect(model.height).to eq(4)
        expect(model.num_low_anchors).to eq(6)
        expect(model.slide_platform_height).to eq(2.5)
      end

      it "handles source without dimension_attributes method" do
        expect { model.copy_dimensions_from(Object.new) }.not_to raise_error
      end
    end

    describe "#total_anchors" do
      it "sums low and high anchors" do
        model.num_low_anchors = 4
        model.num_high_anchors = 2
        expect(model.total_anchors).to eq(6)
      end

      it "handles nil values" do
        model.num_low_anchors = 4
        model.num_high_anchors = nil
        expect(model.total_anchors).to eq(4)
      end
    end

    describe "#max_user_capacity" do
      it "returns maximum user capacity across all heights" do
        model.users_at_1000mm = 10
        model.users_at_1200mm = 15
        model.users_at_1500mm = 12
        model.users_at_1800mm = 8

        expect(model.max_user_capacity).to eq(15)
      end

      it "returns 0 when no capacities are set" do
        expect(model.max_user_capacity).to eq(0)
      end
    end

    describe "dimension check methods" do
      it "#has_slide_attributes?" do
        expect(model.has_slide_attributes?).to be_falsy

        model.slide_platform_height = 2.0
        expect(model.has_slide_attributes?).to be_truthy
      end

      it "#has_structure_attributes?" do
        expect(model.has_structure_attributes?).to be_falsy

        model.stitch_length = 5.0
        expect(model.has_structure_attributes?).to be_truthy
      end

      it "#has_user_height_attributes?" do
        expect(model.has_user_height_attributes?).to be_falsy

        model.containing_wall_height = 1.5
        expect(model.has_user_height_attributes?).to be_truthy
      end

      it "#has_anchorage_attributes?" do
        expect(model.has_anchorage_attributes?).to be_falsy

        model.num_low_anchors = 4
        expect(model.has_anchorage_attributes?).to be_truthy
      end
    end
  end

  describe "scopes" do
    # Need to create actual records for scope testing
    let!(:small_unit) { create(:unit, width: 5, length: 5, height: 2) }
    let!(:medium_unit) { create(:unit, width: 10, length: 10, height: 3) }
    let!(:large_unit) { create(:unit, width: 15, length: 15, height: 4) }

    describe ".within_dimensions" do
      it "finds units within specified dimensions" do
        results = Unit.within_dimensions(12, 12, 3.5)
        expect(results).to include(small_unit, medium_unit)
        expect(results).not_to include(large_unit)
      end
    end

    describe ".by_area_range" do
      it "finds units within area range" do
        results = Unit.by_area_range(50, 150)
        expect(results).to include(medium_unit)
        expect(results).not_to include(small_unit, large_unit)
      end
    end
  end

  describe "class methods" do
    let!(:unit1) { create(:unit, width: 10, length: 10, height: 3) }
    let!(:unit2) { create(:unit, width: 12, length: 12, height: 3.5) }

    describe ".with_similar_dimensions" do
      it "finds units with similar dimensions within tolerance" do
        results = Unit.with_similar_dimensions(unit1, tolerance: 0.2)
        expect(results).to include(unit1, unit2)
      end

      it "excludes units outside tolerance" do
        unit3 = create(:unit, width: 20, length: 20, height: 5)
        results = Unit.with_similar_dimensions(unit1, tolerance: 0.1)
        expect(results).not_to include(unit3)
      end
    end

    describe ".dimension_statistics" do
      it "calculates dimension statistics" do
        # Ensure we only count our test units
        Unit.where.not(id: [unit1.id, unit2.id]).destroy_all

        stats = Unit.dimension_statistics

        expect(stats[:width][:avg]).to be_within(0.01).of(11.0) # (10 + 12) / 2
        expect(stats[:width][:min]).to be_within(0.01).of(10)
        expect(stats[:width][:max]).to be_within(0.01).of(12)
        expect(stats[:area][:avg]).to be_within(0.01).of(122.0) # (100 + 144) / 2
      end
    end
  end
end
