# typed: false

require "rails_helper"

RSpec.describe AssessmentSchema do
  before { AssessmentSchema.reset_cache! }

  describe ".for" do
    it "loads the YAML for an assessment class" do
      schema = described_class.for(Assessments::AnchorageAssessment)

      expect(schema.name).to eq("anchorage_assessment")
      expect(schema.fieldsets).not_to be_empty
    end

    it "memoises the schema per class" do
      first = described_class.for(Assessments::AnchorageAssessment)
      second = described_class.for(Assessments::AnchorageAssessment)

      expect(first).to be(second)
    end
  end

  describe ".load" do
    it "raises if the YAML file is missing" do
      expect { described_class.load("definitely_not_real") }
        .to raise_error(Errno::ENOENT)
    end

    it "builds the named schema's fieldsets and fields from the YAML" do
      schema = described_class.load("anchorage_assessment")

      expect(schema.name).to eq("anchorage_assessment")
      expect(schema.fieldsets.map(&:legend_i18n_key))
        .to eq([:anchor_counts, :anchor_quality])
      expect(schema.fieldsets).to all(be_a(AssessmentSchema::Fieldset))
      expect(schema.fields).to all(be_a(AssessmentSchema::Field))
      expect(schema.fields.map(&:name))
        .to include(:num_low_anchors, :num_high_anchors, :pull_strength)
    end
  end

  describe ".reset_cache!" do
    it "clears memoised schemas so the next lookup reloads" do
      first = described_class.for(Assessments::AnchorageAssessment)
      described_class.reset_cache!
      second = described_class.for(Assessments::AnchorageAssessment)

      expect(second).not_to be(first)
    end
  end

  describe "#find_field" do
    let(:schema) { described_class.for(Assessments::AnchorageAssessment) }

    it "looks up a field by name given a string or a symbol" do
      # pull_strength is not the first field, so a finder that ignores the
      # name predicate would return the wrong field.
      expect(schema.find_field("pull_strength")&.name).to eq(:pull_strength)
      expect(schema.find_field(:pull_strength)&.name).to eq(:pull_strength)
    end

    it "returns nil for an unknown field" do
      expect(schema.find_field(:definitely_not_a_field)).to be_nil
    end
  end

  describe "#fieldsets and #fields" do
    let(:schema) { described_class.for(Assessments::AnchorageAssessment) }

    it "exposes fieldsets with legend keys and fields" do
      legends = schema.fieldsets.map(&:legend_i18n_key)
      expect(legends).to include(:anchor_counts, :anchor_quality)
    end

    it "flattens fieldsets into a list of fields" do
      names = schema.fields.map(&:name)
      expect(names).to include(
        :num_low_anchors,
        :num_high_anchors,
        :anchor_accessories,
        :pull_strength
      )
    end
  end

  describe AssessmentSchema::Field do
    let(:schema) { AssessmentSchema.for(Assessments::AnchorageAssessment) }

    it "exposes name, partial, and attributes" do
      field = schema.find_field(:num_low_anchors)
      expect(field.name).to eq(:num_low_anchors)
      expect(field.partial).to eq(:number_pass_fail_comment)
      expect(field.min).to eq(0)
    end

    it "classifies numeric vs decimal partials" do
      uh_schema = AssessmentSchema.for(Assessments::UserHeightAssessment)

      number_field = uh_schema.find_field(:users_at_1000mm)
      expect(number_field).to be_numeric
      expect(number_field).not_to be_decimal

      decimal_field = uh_schema.find_field(:containing_wall_height)
      expect(decimal_field).to be_decimal
      expect(decimal_field).not_to be_numeric

      mat_schema = AssessmentSchema.for(Assessments::MaterialsAssessment)
      np_field = mat_schema.find_field(:ropes)
      expect(np_field).to be_numeric

      pf_field = schema.find_field(:anchor_accessories)
      expect(pf_field).not_to be_numeric
      expect(pf_field).not_to be_decimal
    end

    it "detects required attribute" do
      ic_schema = AssessmentSchema.for(InspectorCompany)
      expect(ic_schema.find_field(:name)).to be_required
      expect(ic_schema.find_field(:city)).not_to be_required
    end

    it "computes composite fields via ChobbleForms::FieldUtils" do
      field = schema.find_field(:num_low_anchors)
      expect(field.composite_fields)
        .to contain_exactly(:num_low_anchors_pass, :num_low_anchors_comment)
    end
  end

  describe "#partial_for" do
    let(:schema) { AssessmentSchema.for(Assessments::MaterialsAssessment) }

    it "returns the partial for an exact field" do
      expect(schema.partial_for(:ropes))
        .to eq(:number_pass_fail_na_comment)
    end

    it "falls back to the base field for _pass / _comment fields" do
      expect(schema.partial_for(:ropes_pass))
        .to eq(:number_pass_fail_na_comment)
      expect(schema.partial_for(:ropes_comment))
        .to eq(:number_pass_fail_na_comment)
    end

    it "returns nil for an unknown field" do
      expect(schema.partial_for(:nonsense)).to be_nil
    end

    it "uses the exact field's partial even when its name has a suffix" do
      # custom_user_height_comment is defined directly, and its stripped base
      # (custom_user_height) is not a field - so the exact-match branch must
      # win, otherwise the fallback would return nil.
      uh_schema = AssessmentSchema.for(Assessments::UserHeightAssessment)

      expect(uh_schema.partial_for(:custom_user_height_comment))
        .to eq(:text_area)
    end
  end

  describe "#add_not_applicable_fields" do
    it "lists fields whose attributes opt-in to not-applicable" do
      flagged = AssessmentSchema::Field.new(
        field: :flagged,
        partial: :number,
        attributes: {add_not_applicable: true}
      )
      unflagged = AssessmentSchema::Field.new(
        field: :unflagged,
        partial: :number,
        attributes: {min: 0}
      )
      fieldset = AssessmentSchema::Fieldset.new(:section, [flagged, unflagged])
      schema = described_class.new("custom", [fieldset])

      expect(schema.add_not_applicable_fields).to eq([:flagged])
    end
  end

  describe "#exclude" do
    let(:schema) { AssessmentSchema.for(InspectorCompany) }

    it "returns a new schema with the named fields removed" do
      filtered = schema.exclude(:notes)

      expect(filtered).not_to be(schema)
      expect(filtered.find_field(:notes)).to be_nil
      expect(schema.find_field(:notes)).not_to be_nil
    end

    it "preserves field order and other fieldsets" do
      filtered = schema.exclude(:notes)

      expect(filtered.fieldsets.map(&:legend_i18n_key))
        .to eq(schema.fieldsets.map(&:legend_i18n_key))
      expect(filtered.find_field(:name)).not_to be_nil
      expect(filtered.find_field(:active)).not_to be_nil
    end

    it "is a no-op for fields that aren't in the schema" do
      filtered = schema.exclude(:nonexistent)
      expect(filtered.fields.size).to eq(schema.fields.size)
    end
  end
end
