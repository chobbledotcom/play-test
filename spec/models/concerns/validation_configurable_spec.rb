# typed: false

require "rails_helper"

RSpec.describe ValidationConfigurable do
  let(:test_schema) do
    fields = [
      AssessmentSchema::Field.new(
        partial: :text_field,
        field: :inspection_date,
        attributes: {required: true}
      ),
      AssessmentSchema::Field.new(
        partial: :decimal,
        field: :width,
        attributes: {required: true, min: 1, max: 100}
      ),
      AssessmentSchema::Field.new(
        partial: :number,
        field: :height,
        attributes: {min: 10}
      ),
      AssessmentSchema::Field.new(
        partial: :text_area,
        field: :notes_comment,
        attributes: {required: true}
      )
    ]
    fieldset = AssessmentSchema::Fieldset.new(:test_section, fields)
    AssessmentSchema.new("test_model", [fieldset])
  end

  let(:test_model_class) do
    schema = test_schema
    Class.new(ApplicationRecord) do
      self.table_name = "inspections"
      attribute :notes_comment, :string

      define_singleton_method(:name) { "TestModel" }

      include FormConfigurable

      define_singleton_method(:assessment_schema) { schema }

      include ValidationConfigurable
    end
  end

  describe "required field validation" do
    it "adds presence validation for fields with required: true" do
      model = test_model_class.new

      expect(model).not_to be_valid
      expect(model.errors[:inspection_date])
        .to include(I18n.t("errors.messages.blank"))
      expect(model.errors[:width]).to include(I18n.t("errors.messages.blank"))
      expect(model.errors[:height]).to be_empty
      expect(model.errors[:notes_comment]).to be_empty
    end

    it "respects existing validations" do
      model = test_model_class.new(inspection_date: Time.zone.today, width: 0.5)

      expect(model).not_to be_valid
      expect(model.errors[:width])
        .to include(I18n.t("errors.messages.greater_than_or_equal_to", count: 1))
    end

    it "allows valid values" do
      model = test_model_class.new(inspection_date: Time.zone.today, width: 50)

      expect(model.errors[:inspection_date]).to be_empty
      expect(model.errors[:width]).to be_empty
    end

    it "does not validate required or numeric fields hidden on the instance" do
      model = test_model_class.new(width: "invalid")
      schema = test_schema.exclude(:inspection_date, :width)
      model.define_singleton_method(:form_schema) { |user: nil| schema }
      model.valid?

      expect(model.errors[:inspection_date]).to be_empty
      expect(model.errors[:width]).to be_empty
    end
  end
end
