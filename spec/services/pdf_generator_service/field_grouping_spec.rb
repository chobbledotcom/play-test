# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PdfGeneratorService::AssessmentBlockBuilder field grouping" do
  let(:structure_assessment) { create(:structure_assessment) }
  let(:builder) do
    PdfGeneratorService::AssessmentBlockBuilder.new(
      "structure", structure_assessment
    )
  end

  describe "field grouping logic" do
    it "groups pass and comment fields with their base field" do
      fields = [:trough_pass, :trough_comment]
      grouped = builder.send(:group_assessment_fields, fields)

      expect(grouped.keys).to eq([:trough])
      expect(grouped[:trough]).to eq({
        pass: :trough_pass,
        comment: :trough_comment
      })
    end

    it "keeps different base fields separate" do
      fields = [
        :trough_depth, :trough_depth_comment,
        :trough_pass, :trough_comment
      ]
      grouped = builder.send(:group_assessment_fields, fields)

      expect(grouped.keys).to contain_exactly(:trough_depth, :trough)
      expect(grouped[:trough_depth]).to eq({
        base: :trough_depth,
        comment: :trough_depth_comment
      })
      expect(grouped[:trough]).to eq({
        pass: :trough_pass,
        comment: :trough_comment
      })
    end

    it "includes composite fields from form config" do
      # Fields defined as 'trough' in form config should expand
      # to include trough_pass and trough_comment
      ordered_fields = builder.send(:get_form_config_fields)
      trough_fields = ordered_fields.select { |f| f.to_s.include?("trough") }

      expect(trough_fields).to include(:trough_depth)
      expect(trough_fields).to include(:trough_depth_comment)
      expect(trough_fields).to include(:trough_adjacent_panel_width)
      expect(trough_fields).to include(:trough_adjacent_panel_width_comment)
      expect(trough_fields).to include(:trough_pass)
      expect(trough_fields).to include(:trough_comment)
    end

    it "correctly identifies not-applicable fields" do
      not_applicable_fields = builder.send(:get_not_applicable_fields)

      # Fields with add_not_applicable: true in form config
      expect(not_applicable_fields).to include(:trough_depth)

      # Pass/fail fields don't have add_not_applicable
      expect(not_applicable_fields).not_to include(:trough)
      expect(not_applicable_fields).not_to include(:trough_pass)
    end

    it "marks fields as not applicable when value is 0" do
      structure_assessment.update!(
        trough_depth: 0,
        trough_adjacent_panel_width: 0
      )

      # Only fields with add_not_applicable are marked N/A
      is_na = builder.send(:field_is_not_applicable?, :trough_depth)
      expect(is_na).to be true

      # Regular fields with value 0 are not marked N/A
      is_na = builder.send(:field_is_not_applicable?,
        :trough_adjacent_panel_width)
      expect(is_na).to be false

      # Pass fields are never marked N/A
      is_na = builder.send(:field_is_not_applicable?, :trough_pass)
      expect(is_na).to be false
    end

    it "excludes N/A fields but includes unrelated fields" do
      structure_assessment.update!(
        trough_depth: 0, # Will be N/A
        trough_depth_comment: "Not applicable",
        trough_pass: true, # Should still be included
        trough_comment: nil
      )

      blocks = builder.build

      # N/A field should be excluded
      depth_blocks = blocks.select { |b| b.name&.include?("Trough Depth") }
      expect(depth_blocks).to be_empty

      # Pass/fail field should still be included
      check_label = I18n.t("forms.structure.fields.trough")
      check_blocks = blocks.select { |b| b.name == check_label }
      expect(check_blocks).not_to be_empty
      expect(check_blocks.first.pass_fail).to be true
    end
  end
end
