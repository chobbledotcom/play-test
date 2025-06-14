require "rails_helper"

RSpec.describe PdfGeneratorService::AssessmentRenderer do
  let(:renderer) { described_class.new }
  let(:inspection) { create(:inspection) }
  let(:assessment) { inspection.anchorage_assessment }
  
  before do
    setup_renderer("anchorage", assessment)
  end
  
  # Helper methods
  def setup_renderer(assessment_type, assessment_obj)
    renderer.instance_variable_set(:@current_assessment_type, assessment_type)
    renderer.instance_variable_set(:@current_assessment, assessment_obj)
  end
  
  def pass_indicator
    "<font name='Courier'><b><color rgb='00AA00'>[PASS]</color></b></font>"
  end
  
  def fail_indicator
    "<font name='Courier'><b><color rgb='CC0000'>[FAIL]</color></b></font>"
  end
  
  def bold(text)
    "<b>#{text}</b>"
  end
  
  def purple_italic(text)
    "<color rgb='663399'><i>#{text}</i></color>"
  end
  
  def comment_line(text)
    "    #{purple_italic(text)}"
  end
  
  describe "#extract_base_field_name" do
    it "removes _pass suffix" do
      expect(renderer.extract_base_field_name("anchor_type_pass")).to eq("anchor_type")
    end
    
    it "removes _comment suffix" do
      expect(renderer.extract_base_field_name("anchor_type_comment")).to eq("anchor_type")
    end
    
    it "returns unchanged for base fields" do
      expect(renderer.extract_base_field_name("num_low_anchors")).to eq("num_low_anchors")
    end
  end
  
  describe "#group_assessment_fields" do
    it "groups related fields together" do
      field_keys = %i[
        num_low_anchors
        num_anchors_pass
        num_anchors_comment
        anchor_type_pass
        anchor_type_comment
      ]
      
      groups = renderer.group_assessment_fields(field_keys)
      
      expect(groups).to eq({
        "num_low_anchors" => { base: :num_low_anchors },
        "num_anchors" => { pass: :num_anchors_pass, comment: :num_anchors_comment },
        "anchor_type" => { pass: :anchor_type_pass, comment: :anchor_type_comment }
      })
    end
    
    it "skips fields that assessment doesn't respond to" do
      field_keys = %i[
        num_low_anchors
        non_existent_field
        fake_field_pass
      ]
      
      groups = renderer.group_assessment_fields(field_keys)
      
      expect(groups).to eq({
        "num_low_anchors" => { base: :num_low_anchors }
      })
    end
  end
  
  describe "#render_field_line" do
    context "with a simple value field" do
      it "renders the field with label and value" do
        assessment.update!(num_low_anchors: 6)
        fields = { base: :num_low_anchors }
        
        result = renderer.render_field_line(fields)
        
        expect(result).to eq("#{bold('Low anchor points')}: 6")
      end
    end
    
    context "with a pass/fail field" do
      it "renders PASS indicator for true value" do
        assessment.update!(anchor_type_pass: true)
        fields = { pass: :anchor_type_pass }
        
        result = renderer.render_field_line(fields)
        
        expect(result).to eq("#{pass_indicator} #{bold('Anchors permanently closed and metal')}")
      end
      
      it "renders FAIL indicator for false value" do
        assessment.update!(anchor_type_pass: false)
        fields = { pass: :anchor_type_pass }
        
        result = renderer.render_field_line(fields)
        
        expect(result).to eq("#{fail_indicator} #{bold('Anchors permanently closed and metal')}")
      end
    end
    
    context "with value and pass/fail fields" do
      it "renders value with pass/fail status" do
        assessment.update!(num_low_anchors: 6, num_anchors_pass: true)
        fields = { base: :num_low_anchors, pass: :num_anchors_pass }
        
        result = renderer.render_field_line(fields)
        
        expect(result).to eq("#{pass_indicator} #{bold('Low anchor points')}: 6")
      end
    end
    
    context "with empty value" do
      it "renders label with colon only" do
        assessment.update!(num_low_anchors: nil)
        fields = { base: :num_low_anchors }
        
        result = renderer.render_field_line(fields)
        
        expect(result).to eq("#{bold('Low anchor points')}")
      end
    end
  end
  
  describe "#render_comment_line" do
    context "with a comment" do
      it "renders purple italic comment with indentation" do
        assessment.update!(anchor_type_comment: "Using approved D-ring anchors")
        fields = { comment: :anchor_type_comment }
        
        result = renderer.render_comment_line(fields)
        
        expect(result).to eq(comment_line("Using approved D-ring anchors"))
      end
    end
    
    context "without a comment" do
      it "returns nil when comment is blank" do
        assessment.update!(anchor_type_comment: "")
        fields = { comment: :anchor_type_comment }
        
        result = renderer.render_comment_line(fields)
        
        expect(result).to be_nil
      end
      
      it "returns nil when no comment field" do
        fields = {}
        
        result = renderer.render_comment_line(fields)
        
        expect(result).to be_nil
      end
    end
  end
  
  describe "full field group rendering" do
    before do
      renderer.instance_variable_set(:@current_assessment_fields, [])
    end
    
    it "renders field with value, pass status, and comment on separate lines" do
      assessment.update!(
        num_low_anchors: 6,
        num_anchors_pass: false,
        num_anchors_comment: "Need 2 more anchors for this size unit"
      )
      
      fields = {
        base: :num_low_anchors,
        pass: :num_anchors_pass,
        comment: :num_anchors_comment
      }
      
      renderer.send(:render_field_group, "num_anchors", fields)
      
      output_fields = renderer.instance_variable_get(:@current_assessment_fields)
      
      expect(output_fields).to eq([
        "#{fail_indicator} #{bold('Low anchor points')}: 6",
        comment_line("Need 2 more anchors for this size unit")
      ])
    end
  end
end