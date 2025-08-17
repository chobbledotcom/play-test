# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::AssessmentBlockBuilder do
  let(:inspection) { create(:inspection) }
  let(:assessment) { inspection.materials_assessment }
  let(:builder) { described_class.new("mock_form", assessment) }

  define_method(:mock_form_translations) do
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

  describe "#get_field_label (private method)" do
    before do
      # Mock I18n responses
      allow(I18n).to receive(:t!).and_call_original
    end

    it "prioritizes base field label" do
      fields = {base: :ropes, pass: :ropes_pass, comment: :ropes_comment}

      expect(I18n).to receive(:t!).with("forms.mock_form.fields.ropes")
        .and_return("Ropes Label")

      label = builder.send(:get_field_label, fields)
      expect(label).to eq("Ropes Label")
    end

    it "uses pass field label when no base field" do
      fields = {pass: :fabric_strength_pass, comment: :fabric_strength_comment}

      expect(I18n).to receive(:t!).with("forms.mock_form.fields.fabric_strength")
        .and_return("Fabric Pass Label")

      label = builder.send(:get_field_label, fields)
      expect(label).to eq("Fabric Pass Label")
    end

    it "uses comment field label for standalone comments" do
      fields = {comment: :custom_comment}

      expect(I18n).to receive(:t!).with("forms.mock_form.fields.custom")
        .and_return("Custom Comment Label")

      label = builder.send(:get_field_label, fields)
      expect(label).to eq("Custom Comment Label")
    end

    it "raises error for unknown field types" do
      fields = {unknown_type: :some_field}

      expect {
        builder.send(:get_field_label, fields)
      }.to raise_error(RuntimeError, "No valid fields found: {unknown_type: :some_field}")
    end
  end

  describe "#determine_pass_value (private method)" do
    it "returns pass field value when pass field exists" do
      fields = {base: :ropes, pass: :ropes_pass}
      allow(assessment).to receive(:ropes_pass).and_return(true)

      result = builder.send(:determine_pass_value, fields, :ropes, 5)
      expect(result).to eq(true)
    end

    it "returns value when main field is a pass field" do
      fields = {pass: :thread_pass}
      # Mock the assessment to return false for thread_pass
      allow(assessment).to receive(:thread_pass).and_return(false)
      # When the main field IS the pass field, it returns the value from assessment
      result = builder.send(:determine_pass_value, fields, :thread_pass, true)
      expect(result).to eq(false) # Returns assessment value, not passed value
    end

    it "returns nil when no pass field and main field is not pass" do
      fields = {base: :measurement, comment: :measurement_comment}

      result = builder.send(:determine_pass_value, fields, :measurement, 42)
      expect(result).to be_nil
    end
  end

  describe "#get_form_config_fields (private method)" do
    context "with user_height assessment" do
      let(:assessment) { inspection.user_height_assessment }
      let(:builder) { described_class.new("user_height", assessment) }

      it "includes standalone comment fields from form config" do
        fields = builder.send(:get_form_config_fields)

        expect(fields).to include(:custom_user_height_comment)
      end

      it "expands composite fields correctly" do
        fields = builder.send(:get_form_config_fields)

        # Should include base fields and their comment variants
        expect(fields).to include(:containing_wall_height)
        expect(fields).to include(:containing_wall_height_comment)
      end

      it "maintains field order from form configuration" do
        fields = builder.send(:get_form_config_fields)

        # Check that fields appear in the order defined in the form config
        wall_height_index = fields.index(:containing_wall_height)
        play_area_index = fields.index(:play_area_length)
        user_count_index = fields.index(:users_at_1000mm)
        custom_comment_index = fields.index(:custom_user_height_comment)

        expect(wall_height_index).to be < play_area_index
        expect(play_area_index).to be < user_count_index
        expect(user_count_index).to be < custom_comment_index
      end
    end
  end

  describe "edge cases and boundary conditions" do
    it "handles assessment with no fields gracefully" do
      allow(assessment).to receive(:class).and_return(double(form_fields: []))
      mock_form_translations

      blocks = described_class.build_from_assessment("mock_form", assessment)

      expect(blocks.size).to eq(1) # Just the header
      expect(blocks.first.type).to eq(:header)
    end

    it "handles nil values correctly" do
      allow(assessment).to receive(:ropes).and_return(nil)
      allow(assessment).to receive(:ropes_pass).and_return(nil)
      allow(assessment).to receive(:ropes_comment).and_return(nil)
      mock_form_translations

      builder = described_class.new("mock_form", assessment)
      fields = {base: :ropes, pass: :ropes_pass, comment: :ropes_comment}

      # Mock the field grouping
      allow(builder).to receive(:get_form_config_fields).and_return([:ropes, :ropes_pass, :ropes_comment])
      allow(builder).to receive(:group_assessment_fields).and_return({ropes: fields})

      blocks = builder.build

      # Should create header and value block even with nil values
      expect(blocks.count(&:value?)).to be >= 1
      # Should not create comment block for nil comment
      expect(blocks.select(&:comment?)).to be_empty
    end

<<<<<<< HEAD
    it "correctly identifies pass fields vs other boolean fields" do
      # Test that the builder correctly distinguishes between actual pass/fail fields
      # and other fields that might have "pass" in their name
      
      # Test with known pass field from materials assessment
      assessment.fabric_strength_pass = true
      fields = {pass: :fabric_strength_pass}
      
      pass_value = builder.send(:determine_pass_value, fields, :fabric_strength_pass, true)
      expect(pass_value).to eq(true)
      
      # Test field extraction logic for fields with "pass" in the name
      base_name = builder.send(:extract_base_field_name, "fabric_strength_pass")
      expect(base_name).to eq("fabric_strength")
      
      # Test with another known pass field
      base_name = builder.send(:extract_base_field_name, "thread_pass")
      expect(base_name).to eq("thread")
      
      # Test that when main field is the pass field itself, it returns the assessment value
      assessment.thread_pass = false
      fields_with_only_pass = {pass: :thread_pass}
      pass_value = builder.send(:determine_pass_value, fields_with_only_pass, :thread_pass, true)
      # When the main field IS the pass field, it returns the value from assessment
      expect(pass_value).to eq(false)
      
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
          runout_pass: true,
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
          fabric_strength_pass: false,
          fabric_strength_comment: "",
          thread_pass: true
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

        # Boolean false should remain false - fabric_strength has no base field, only pass field
        fabric_block = value_blocks.find do |b|
          b.name&.include?("Fabric")
        end
        expect(fabric_block).not_to be_nil
        expect(fabric_block.pass_fail).to eq(false)

        # Boolean true should remain true - thread has no base field, only pass field
        thread_block = value_blocks.find do |b|
          b.name&.include?("Thread")
        end
        expect(thread_block).not_to be_nil
        expect(thread_block.pass_fail).to eq(true)
      end
    end
  end
end
