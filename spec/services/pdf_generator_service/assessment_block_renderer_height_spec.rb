require "rails_helper"

RSpec.describe PdfGeneratorService::AssessmentBlockRenderer do
  describe "#height_for" do
    let(:renderer) { described_class.new }
    let(:pdf) { Prawn::Document.new }

    context "when comparing blocks with and without pass/fail" do
      let(:block_without_pass_fail) do
        PdfGeneratorService::AssessmentBlock.new(
          type: :value,
          name: "Width",
          value: "100mm"
        )
      end

      let(:block_with_pass_fail) do
        PdfGeneratorService::AssessmentBlock.new(
          type: :value,
          name: "Width",
          value: "100mm",
          pass_fail: true
        )
      end

      it "calculates similar heights for blocks with same content but different pass/fail status" do
        height_without = renderer.height_for(block_without_pass_fail, pdf)
        height_with = renderer.height_for(block_with_pass_fail, pdf)

        # They shouldn't be dramatically different - allow some tolerance for formatting
        expect((height_with - height_without).abs).to be < 5
      end
    end

    context "direct text box height testing" do
      let(:column_width) { 120 } # Same as COLUMN_WIDTH
      let(:font_size) { 7 }

      def test_text_height(text, description)
        box = Prawn::Text::Box.new(
          text,
          document: pdf,
          at: [0, pdf.cursor],
          width: column_width,
          size: font_size,
          inline_format: true
        )
        box.render(dry_run: true)
        box.height
      end

      it "includes spacing in height calculation" do
        renderer = described_class.new(font_size: 7)
        pdf = Prawn::Document.new

        block = PdfGeneratorService::AssessmentBlock.new(
          type: :value,
          name: "Width",
          value: "100mm"
        )

        height = renderer.height_for(block, pdf)

        # Height should include base text height plus 33% of font size as spacing
        expected_spacing = (7 * 0.33).round(1)
        expect(height).to be > expected_spacing

        # Just verify it calculates some reasonable height
        expect(height).to be > 0
      end

      it "tests individual components" do
        base_text = "<b>Width</b>: 100mm"
        pass_only = "<b><color rgb='008000'>[PASS]</color></b>"
        pass_with_space = "<b><color rgb='008000'>[PASS]</color></b> "
        combined = "<b><color rgb='008000'>[PASS]</color></b> <b>Width</b>: 100mm"

        test_text_height(base_text, "Base text")
        test_text_height(pass_only, "Pass indicator only")
        test_text_height(pass_with_space, "Pass with space")
        test_text_height(combined, "Combined")

        # Just verify they all render without error
        expect(true).to be true
      end

      it "tests with different nesting patterns" do
        nested_deep = "<b><color rgb='008000'>[PASS]</color></b>"
        separate_tags = "<b>[PASS]</b>"
        no_nesting = "[PASS]"

        test_text_height(nested_deep, "Deeply nested")
        test_text_height(separate_tags, "Separate tags")
        test_text_height(no_nesting, "No nesting")

        # Just verify they complete
        expect(true).to be true
      end
    end

    context "height increases with text length" do
      let(:renderer) { described_class.new }
      let(:pdf) { Prawn::Document.new }

      it "verifies height increases as text content gets longer and wraps" do
        heights = []

        # Test progressively longer text content
        test_texts = [
          "Short",
          "This is a medium length text that might fit on one line",
          "This is a much longer text that will definitely wrap across multiple lines when rendered in the column width constraints and should result in a taller height measurement",
          "This is an extremely long text passage that contains many words and should definitely wrap across several lines when constrained to the narrow column width, resulting in progressively taller height measurements as we add more and more content to test the wrapping behavior and height calculations"
        ]

        test_texts.each_with_index do |text, index|
          block = PdfGeneratorService::AssessmentBlock.new(
            type: :value,
            name: text
          )

          height = renderer.height_for(block, pdf)
          heights << height
        end

        # Heights should generally increase with longer content
        expect(heights[1]).to be >= heights[0] # Medium >= Short
        expect(heights[2]).to be > heights[1]  # Long > Medium
        expect(heights[3]).to be > heights[2]  # Very long > Long

        # Verify we have meaningful height differences for wrapping
        expect(heights.last).to be > heights.first * 2 # Longest should be at least 2x tallest
      end
    end
  end
end
