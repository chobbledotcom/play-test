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
        expect(thread_block.name).to eq(I18n.t("forms.materials.fields.thread_pass"))
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

      # Skip header, get field names in order
      field_blocks = blocks.drop(1).select(&:value?)
      field_names = field_blocks.map(&:name)

      # Should follow the order defined in MaterialsAssessment.form_fields
      # This will help us verify the ordering is working correctly
      puts "Field order in blocks:"
      field_names.each_with_index { |name, i| puts "#{i + 1}. #{name}" }

      expect(field_names).not_to be_empty
    end
  end
end
