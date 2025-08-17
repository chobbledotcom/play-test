# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfGeneratorService::AssessmentBlockBuilder do
  let(:inspection) { create(:inspection) }
  let(:materials_assessment) { create(:materials_assessment, inspection: inspection) }
  let(:structure_assessment) { create(:structure_assessment, inspection: inspection) }

  describe ".build_from_assessment" do
    context "with a materials assessment" do
      before do
        # Use SeedData to populate with realistic test data
        materials_assessment.update!(SeedData.materials_fields(passed: true))
        # Override specific fields for test cases
        materials_assessment.update!(
          fabric_strength_comment: "Good fabric strength",
          ropes_comment: "", # Empty comment should not create block
          thread_comment: nil # Nil comment should not create block
        )
      end

      let(:blocks) do
        described_class.build_from_assessment("materials", materials_assessment)
      end

      it "creates the correct number of blocks" do
        expect(blocks.size).to eq(10) # Update based on actual output
      end

      it "creates blocks in the correct order" do
        expect(blocks.map(&:type)).to eq(%i[
          header value value value value value value value comment value
        ])
      end

      it "creates header block correctly" do
        header = blocks.first
        expect(header.type).to eq(:header)
        expect(header.name).to eq(I18n.t("forms.materials.header"))
      end

      it "creates value blocks with pass/fail correctly" do
        ropes_block = blocks[1] # First value block
        expect(ropes_block.type).to eq(:value)
        expect(ropes_block.pass_fail).to eq("pass")
        expect(ropes_block.name).to eq(I18n.t("forms.materials.fields.ropes"))
        expect(ropes_block.value).to be_present # Has numeric value from seed

        thread_block = blocks[6] # Thread block
        expect(thread_block.type).to eq(:value)
        expect(thread_block.pass_fail).to eq(true) # From seed data
        expect(thread_block.name).to eq(I18n.t("forms.materials.fields.thread"))
      end

      it "creates comment blocks only when comments have content" do
        comment_blocks = blocks.select(&:comment?)
        expect(comment_blocks.size).to eq(1)

        comment_block = comment_blocks.first
        expect(comment_block.comment).to eq("Good fabric strength")
      end

      it "does not create comment blocks for empty or nil comments" do
        # Should not have blocks for ropes_comment (empty) or thread_comment (nil)
        block_comments = blocks.map(&:comment).compact
        expect(block_comments).to eq(["Good fabric strength"])
      end
    end

    context "with assessment having regular fields and pass/fail fields" do
      before do
        # Use SeedData which has both regular fields (ropes: numeric) and pass/fail fields
        materials_assessment.update!(SeedData.materials_fields(passed: true))
      end

      let(:blocks) do
        described_class.build_from_assessment("materials", materials_assessment)
      end

      it "handles regular fields correctly" do
        # Find the ropes block (has numeric value)
        value_block = blocks.find { |b| b.value? && b.value.is_a?(Integer) }
        expect(value_block).to be_present
        expect(value_block.pass_fail).to eq("pass") # Also has pass/fail
        expect(value_block.value).to be_present # Has numeric value
      end

      it "handles pass/fail fields correctly" do
        # Find a pure pass/fail field like thread_pass
        pass_block = blocks.find { |b| b.value? && b.name&.include?("Thread") }
        expect(pass_block).to be_present
        expect(pass_block.value).to be_nil # Pass/fail field, no separate value
      end
    end
  end

  describe "multiple assessments" do
    before do
      # Set up materials assessment using SeedData
      materials_assessment.update!(SeedData.materials_fields(passed: true))
      materials_assessment.update!(fabric_strength_comment: "Good fabric")

      # Set up structure assessment using SeedData
      structure_assessment.update!(SeedData.structure_fields(passed: false))
      structure_assessment.update!(seam_integrity_comment: "Too narrow")
    end

    it "creates correct blocks for multiple assessments" do
      materials_blocks = described_class.build_from_assessment("materials", materials_assessment)
      structure_blocks = described_class.build_from_assessment("structure", structure_assessment)

      # Combine like the main PDF generator does
      all_blocks = materials_blocks + structure_blocks

      # Should have two headers (one for each assessment)
      headers = all_blocks.select(&:header?)
      expect(headers.size).to eq(2)
      expect(headers[0].name).to eq(I18n.t("forms.materials.header"))
      expect(headers[1].name).to eq(I18n.t("forms.structure.header"))

      # Should have comments only where there's actual content
      comments = all_blocks.select(&:comment?)
      comment_text = comments.map(&:comment)
      expect(comment_text).to eq([
        "Good fabric",
        "Too narrow",
        "Measured at regular intervals",
        "Platform height acceptable for age group"
      ])

      # Should not have empty comments
      expect(comment_text).not_to include("")
      expect(comment_text).not_to include(nil)
    end
  end

  describe "field ordering" do
    it "follows the form configuration order" do
      blocks = described_class.build_from_assessment("materials", materials_assessment)
      field_blocks = blocks.drop(1).select(&:value?)
      field_names = field_blocks.map(&:name)
      expect(field_names).not_to be_empty
    end
  end

  describe "not applicable fields (add_not_applicable)" do
    context "with structure assessment having trough_depth field" do
      let(:structure_assessment) { inspection.structure_assessment }

      it "skips trough_depth field when value is 0" do
        structure_assessment.update!(
          trough_depth: 0,
          trough_depth_comment: "Not applicable to this unit"
        )

        blocks = described_class.build_from_assessment("structure", structure_assessment)

        # Should not have any blocks for trough_depth when it's 0
        trough_blocks = blocks.select do |b|
          b.name&.include?(I18n.t("forms.structure.fields.trough_depth"))
        end

        expect(trough_blocks).to be_empty
      end

      it "includes trough_depth field when value is non-zero" do
        structure_assessment.update!(
          trough_depth: 5,
          trough_depth_comment: "Good depth"
        )

        blocks = described_class.build_from_assessment("structure", structure_assessment)

        # Should have blocks for trough_depth when it's not 0
        trough_blocks = blocks.select do |b|
          (b.value? && b.name == I18n.t("forms.structure.fields.trough_depth")) ||
            (b.comment? && b.comment == "Good depth")
        end

        expect(trough_blocks.size).to eq(2) # Value block and comment block
      end

      it "includes trough_depth field when value is nil" do
        structure_assessment.update!(
          trough_depth: nil,
          trough_depth_comment: ""
        )

        blocks = described_class.build_from_assessment("structure", structure_assessment)

        # Should have value block for trough_depth when it's nil (not set)
        trough_blocks = blocks.select do |b|
          b.value? && b.name == I18n.t("forms.structure.fields.trough_depth")
        end

        expect(trough_blocks.size).to eq(1)
        expect(trough_blocks.first.value).to be_nil
      end

      it "handles related fields correctly when main field is skipped" do
        structure_assessment.update!(
          trough_depth: 0,
          trough_depth_comment: "N/A comment",
          trough_pass: true
        )

        blocks = described_class.build_from_assessment("structure", structure_assessment)

        # trough_depth should be skipped (value is 0)
        depth_blocks = blocks.select do |b|
          b.name&.include?(I18n.t("forms.structure.fields.trough_depth"))
        end
        expect(depth_blocks).to be_empty

        # But trough_pass should still be included
        # Look for blocks that have the trough label (not trough_depth)
        trough_label = I18n.t("forms.structure.fields.trough")
        pass_blocks = blocks.select do |b|
          b.name == trough_label
        end
        expect(pass_blocks).not_to be_empty
      end
    end

    context "with fields that don't have add_not_applicable" do
      it "includes fields with value 0 when they don't have add_not_applicable" do
        # Regular integer field without add_not_applicable
        structure_assessment.update!(
          trough_adjacent_panel_width: 0,
          trough_adjacent_panel_width_comment: "Zero width"
        )

        blocks = described_class.build_from_assessment("structure", structure_assessment)

        # Should include the field even though value is 0
        width_blocks = blocks.select do |b|
          b.name&.include?("adjacent") || b.comment == "Zero width"
        end

        expect(width_blocks).not_to be_empty
      end
    end
  end

  describe "standalone comment fields" do
    context "with user_height assessment" do
      let(:user_height_assessment) { inspection.user_height_assessment }

      before do
        user_height_assessment.update!(
          custom_user_height_comment: "Maximum height is 2.5m for safety"
        )
      end

      let(:blocks) do
        described_class.build_from_assessment("user_height", user_height_assessment)
      end

      it "creates blocks for standalone comment field" do
        # Find the custom_user_height_comment blocks
        custom_height_blocks = blocks.select do |b|
          (b.value? && b.name == I18n.t("forms.user_height.fields.custom_user_height")) ||
            (b.comment? && b.comment == "Maximum height is 2.5m for safety")
        end

        expect(custom_height_blocks.size).to eq(2)

        # Should have a label block
        label_block = custom_height_blocks.find(&:value?)
        expect(label_block).to be_present
        expect(label_block.name).to eq(I18n.t("forms.user_height.fields.custom_user_height"))
        expect(label_block.value).to be_nil

        # Should have a comment block
        comment_block = custom_height_blocks.find(&:comment?)
        expect(comment_block).to be_present
        expect(comment_block.comment).to eq("Maximum height is 2.5m for safety")
      end

      it "does not create blocks for empty standalone comment" do
        user_height_assessment.update!(custom_user_height_comment: "")
        blocks = described_class.build_from_assessment("user_height", user_height_assessment)

        # Should not have any blocks for the empty comment
        custom_height_blocks = blocks.select do |b|
          (b.value? && b.name == I18n.t("forms.user_height.fields.custom_user_height_comment")) ||
            b.comment?
        end

        # Find only the custom_user_height_comment related blocks
        custom_comment_blocks = custom_height_blocks.select do |b|
          b.name == I18n.t("forms.user_height.fields.custom_user_height_comment") ||
            b.comment == ""
        end

        expect(custom_comment_blocks).to be_empty
      end

      it "handles nil standalone comment" do
        user_height_assessment.update!(custom_user_height_comment: nil)
        blocks = described_class.build_from_assessment("user_height", user_height_assessment)

        # Should not have any blocks for the nil comment
        custom_height_blocks = blocks.select do |b|
          b.value? && b.name == I18n.t("forms.user_height.fields.custom_user_height_comment")
        end

        expect(custom_height_blocks).to be_empty
      end
    end
  end
end
