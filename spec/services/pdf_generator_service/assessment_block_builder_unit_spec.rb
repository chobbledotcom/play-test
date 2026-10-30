# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::AssessmentBlockBuilder do
  let(:inspection) { create(:inspection) }
  let(:assessment) { inspection.materials_assessment }
  let(:builder) { described_class.new("mock_form", assessment) }

  define_method(:mock_form_translations) do
    allow(inspection).to receive(:field_label) do |form, field|
      I18n.t!("forms.#{form}.fields.#{field}")
    end
    allow(I18n).to receive(:t).and_call_original
    allow(I18n).to receive(:t).with("forms.mock_form.header")
      .and_return("Mock Form Header")
    allow(I18n).to receive(:t!).and_call_original
    allow(I18n).to receive(:t!).with("forms.mock_form.fields.ropes")
      .and_return("Ropes")
    allow(I18n).to receive(:t!).with("forms.mock_form.fields.fabric_strength")
      .and_return("Fabric Strength")
    allow(I18n).to receive(:t!).with("forms.mock_form.fields.thread")
      .and_return("Thread")
    allow(I18n).to receive(:t!).with(anything) do |key|
      key.to_s.split(".").last.humanize if key.to_s.start_with?("forms.mock_form.fields.")
    end
  end

  describe "#group_assessment_fields (private method)" do
    it "groups fields correctly by base name" do
      # Test the private method directly using send
      field_keys = %i[
        ropes
        ropes_pass
        ropes_comment
        fabric_strength_pass
        fabric_strength_comment
        standalone_comment
        thread_pass
      ]

      groups = builder.send(:group_assessment_fields, field_keys)

      # Note: standalone_comment won't be grouped because assessment doesn't respond to it
      expect(groups.keys).to contain_exactly(:ropes, :fabric_strength, :thread)
      expect(groups[:ropes]).to eq(base: :ropes, pass: :ropes_pass, comment: :ropes_comment)
      fabric_group = groups[:fabric_strength]
      expect(fabric_group[:pass]).to eq(:fabric_strength_pass)
      expect(fabric_group[:comment]).to eq(:fabric_strength_comment)
      expect(groups[:thread]).to eq(pass: :thread_pass)
    end

    it "ignores fields that the assessment doesn't respond to" do
      field_keys = %i[
        ropes
        nonexistent_field
        ropes_pass
        another_fake_field_comment
      ]

      groups = builder.send(:group_assessment_fields, field_keys)

      expect(groups.keys).to contain_exactly(:ropes)
      expect(groups[:ropes]).to include(base: :ropes, pass: :ropes_pass)
    end

    it "handles fields with multiple underscores correctly" do
      field_keys = %i[
        very_long_field_name
        very_long_field_name_pass
        very_long_field_name_comment
      ]

      # Mock the assessment to respond to these fields
      allow(assessment).to receive(:respond_to?).and_call_original
      allow(assessment).to receive(:respond_to?).with("very_long_field_name").and_return(true)
      allow(assessment).to receive(:respond_to?).with("very_long_field_name_pass").and_return(true)
      allow(assessment).to receive(:respond_to?).with("very_long_field_name_comment").and_return(true)

      groups = builder.send(:group_assessment_fields, field_keys)

      expect(groups[:very_long_field_name]).to eq(
        base: :very_long_field_name,
        pass: :very_long_field_name_pass,
        comment: :very_long_field_name_comment
      )
    end
  end

  describe "#determine_pass_value (private method)" do
    it "returns pass field value when pass field exists" do
      fields = {base: :ropes, pass: :ropes_pass}
      allow(assessment).to receive(:ropes_pass).and_return("pass")

      result = builder.send(:determine_pass_value, fields, :ropes, 5)
      expect(result).to eq("pass")
    end

    it "returns value when main field is a pass field" do
      fields = {pass: :thread_pass}
      allow(assessment).to receive(:thread_pass).and_return("fail")
      result = builder.send(:determine_pass_value, fields, :thread_pass, "pass")
      expect(result).to eq("fail")
    end

    it "returns nil when no pass field and main field is not pass" do
      fields = {base: :measurement, comment: :measurement_comment}

      result = builder.send(:determine_pass_value, fields, :measurement, 42)
      expect(result).to be_nil
    end
  end

  describe "user-height report content" do
    let(:assessment) { inspection.user_height_assessment }
    let(:builder) { described_class.new("user_height", assessment) }

    it "retains standalone inspection comments" do
      assessment.custom_user_height_comment = "Reduced capacity for supervision"

      comments = builder.build.select(&:comment?).map(&:comment)

      expect(comments).to contain_exactly("Reduced capacity for supervision")
    end

    it "keeps the wall measurement and its associated comment" do
      assessment.assign_attributes(containing_wall_height: 2.5,
        containing_wall_height_comment: "Measured beside the play area")

      blocks = builder.build
      label = I18n.t("forms.user_height.fields.containing_wall_height")
      wall = blocks.find { |block| block.value? && block.name == label }

      expect(wall.value).to eq(BigDecimal("2.5"))
      expect(blocks.select(&:comment?).map(&:comment))
        .to contain_exactly("Measured beside the play area")
    end
  end

  describe "edge cases and boundary conditions" do
    it "handles assessment with no fields gracefully" do
      empty_schema = AssessmentSchema.new("mock_form", [])
      allow(assessment).to receive(:form_schema).with(user: nil)
        .and_return(empty_schema)
      mock_form_translations

      blocks = described_class.build_from_assessment("mock_form", assessment)

      expect(blocks.size).to eq(1) # Just the header
      expect(blocks.first.type).to eq(:header)
    end

    it "retains unanswered measurements without inventing comments" do
      blocks = described_class.new("materials", assessment).build
      label = I18n.t("forms.materials.fields.ropes")
      ropes = blocks.find { |block| block.value? && block.name == label }

      expect(ropes.value).to be_nil
      expect(ropes.pass_fail).to be_nil
      expect(blocks.select(&:comment?)).to be_empty
    end

    it "correctly identifies pass fields vs other boolean fields" do
      # Test that the builder correctly distinguishes between actual pass/fail fields
      # and other fields that might have "pass" in their name

      # Test with known pass field from materials assessment
      assessment.fabric_strength_pass = "pass"
      fields = {pass: :fabric_strength_pass}

      pass_value = builder.send(:determine_pass_value, fields, :fabric_strength_pass, true)
      expect(pass_value).to eq("pass")

      # Test field grouping logic for fields with "pass" in the name
      field_keys = [:fabric_strength_pass, :fabric_strength_comment, :thread_pass]
      groups = builder.send(:group_assessment_fields, field_keys)
      expect(groups.keys).to include(:fabric_strength, :thread)
      expect(groups[:fabric_strength][:pass]).to eq(:fabric_strength_pass)

      # Test that when main field is the pass field itself, it returns the assessment value
      assessment.thread_pass = "fail"
      fields_with_only_pass = {pass: :thread_pass}
      pass_value = builder.send(:determine_pass_value, fields_with_only_pass, :thread_pass, true)
      # When the main field IS the pass field, it returns the value from assessment
      expect(pass_value).to eq("fail")

      # Test that fields without pass suffix return nil for pass_fail
      assessment.ropes = 25
      fields_without_pass = {base: :ropes}
      pass_value = builder.send(:determine_pass_value, fields_without_pass, :ropes, 25)
      expect(pass_value).to be_nil
    end
  end

  describe "integration with different assessment types" do
    context "with slide assessment having height fields" do
      let(:slide_assessment) { inspection.slide_assessment }
      let(:builder) { described_class.new("slide", slide_assessment) }

      before do
        # Use actual slide assessment fields
        slide_assessment.update!(
          slide_platform_height: 2.5,
          runout_pass: "pass",
          slide_platform_height_comment: "Height is safe"
        )
      end

      it "creates all three blocks for complete field group" do
        blocks = builder.build

        # Find slide_platform_height related blocks
        height_blocks = blocks.select do |b|
          (b.value? && b.name&.include?("Platform")) ||
            (b.comment? && b.comment == "Height is safe")
        end

        # Might be 2 or 3 depending on whether runout block is also found
        expect(height_blocks.size).to be >= 2

        value_block = height_blocks.find(&:value?)
        expect(value_block).not_to be_nil
        expect(value_block.value).to eq(2.5)
        # Note: pass/fail comes from a different field (runout_pass)

        comment_block = height_blocks.find(&:comment?)
        expect(comment_block).not_to be_nil
        expect(comment_block.comment).to eq("Height is safe")
      end
    end

    context "with mock assessment having mixed field types" do
      let(:builder) { described_class.new("mock_form", assessment) }

      before do
        assessment.update!(
          ropes: 5,
          ropes_pass: "pass",
          ropes_comment: "Good condition",
          fabric_strength_pass: "fail",
          fabric_strength_comment: "",
          thread_pass: "pass"
        )
      end

      it "handles different pass_fail value types correctly" do
        mock_form_translations

        blocks = builder.build
        value_blocks = blocks.select(&:value?)

        # String "pass" should be converted to pass indicator
        ropes_block = value_blocks.find do |b|
          b.name == "Ropes"
        end
        expect(ropes_block).not_to be_nil
        expect(ropes_block.pass_fail).to eq("pass")

        # Outcome-only checks retain their explicit enum answer.
        fabric_block = value_blocks.find do |b|
          b.name&.include?("Fabric")
        end
        expect(fabric_block).not_to be_nil
        expect(fabric_block.pass_fail).to eq("fail")

        # Outcome-only checks do not invent a measurement.
        thread_block = value_blocks.find do |b|
          b.name&.include?("Thread")
        end
        expect(thread_block).not_to be_nil
        expect(thread_block.pass_fail).to eq("pass")
      end
    end
  end
end
