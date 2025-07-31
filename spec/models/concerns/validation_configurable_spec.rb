require "rails_helper"

RSpec.describe ValidationConfigurable do
  let(:test_model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "inspections"

      def self.name
        "TestModel"
      end

      include FormConfigurable

      def self.test_fields
        [
          {
            partial: "text_field",
            field: :inspection_date,
            attributes: {required: true}
          },
          {
            partial: "decimal",
            field: :width,
            attributes: {required: true, min: 1, max: 100}
          },
          {
            partial: "number",
            field: :height,
            attributes: {min: 10}
          }
        ]
      end

      def self.form_fields
        [{legend_i18n_key: "test_section", fields: test_fields}]
      end

      include ValidationConfigurable
    end
  end

  describe "required field validation" do
    it "adds presence validation for fields with required: true" do
      model = test_model_class.new

      expect(model).not_to be_valid
      expect(model.errors[:inspection_date]).to include("can't be blank")
      expect(model.errors[:width]).to include("can't be blank")
      expect(model.errors[:height]).to be_empty
    end

    it "respects existing validations" do
      model = test_model_class.new(inspection_date: Time.zone.today, width: 0.5)

      expect(model).not_to be_valid
      expect(model.errors[:width])
        .to include("must be greater than or equal to 1")
    end

    it "allows valid values" do
      model = test_model_class.new(inspection_date: Time.zone.today, width: 50)

      expect(model.errors[:inspection_date]).to be_empty
      expect(model.errors[:width]).to be_empty
    end
  end
end
