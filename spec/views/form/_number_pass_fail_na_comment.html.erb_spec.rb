require "rails_helper"

# Test model for form specs
class NumberPassFailNaCommentTestModel
  include ActiveModel::Model
  attr_accessor :slide_platform_height, :slide_platform_height_pass,
    :slide_platform_height_comment, :beam_width, :beam_width_pass,
    :beam_width_comment, :anchor_spacing, :anchor_spacing_pass,
    :anchor_spacing_comment

  def persisted? = false

  # Mock enum behavior for _pass fields to support N/A radio buttons
  def self.defined_enums
    {
      "slide_platform_height_pass" => {"fail" => 0, "pass" => 1, "na" => 2},
      "beam_width_pass" => {"fail" => 0, "pass" => 1, "na" => 2},
      "anchor_spacing_pass" => {"fail" => 0, "pass" => 1, "na" => 2}
    }
  end
end

RSpec.describe "form/_number_pass_fail_na_comment.html.erb", type: :view do
  let(:test_model) { NumberPassFailNaCommentTestModel.new }
  let(:field) { :slide_platform_height }

  # Common selectors
  let(:form_grid_selector) { "div.form-grid.number-radio-comment" }
  let(:model_name) { "number_pass_fail_na_comment_test_model" }
  let(:number_input_selector) do
    "input[type=\"number\"][name=\"#{model_name}[slide_platform_height]\"]"
  end
  let(:pass_radio_selector) do
    "input[type=\"radio\"][name=\"#{model_name}[slide_platform_height_pass]\"][value=\"true\"]"
  end
  let(:fail_radio_selector) do
    "input[type=\"radio\"][name=\"#{model_name}[slide_platform_height_pass]\"][value=\"false\"]"
  end
  let(:na_checkbox_selector) do
    "input[type=\"checkbox\"]#slide_platform_height_pass_na_checkbox"
  end
  let(:comment_textarea_selector) do
    "textarea[name=\"#{model_name}[slide_platform_height_comment]\"]"
  end

  # Expected text labels
  let(:field_label) { "Slide Platform Height" }
  let(:pass_label) { "Pass" }
  let(:fail_label) { "Fail" }
  let(:na_label) { "Not Applicable" }
  let(:comment_label) { "Comment" }

  before do
    # Include the ApplicationHelper methods
    view.extend ApplicationHelper

    view.form_with(model: test_model, url: "/", local: true) do |f|
      @_current_form = f
      ""
    end
    @_current_i18n_base = "test.forms"

    I18n.backend.store_translations(:en, {
      test: {
        forms: {
          fields: {
            slide_platform_height: "Slide Platform Height",
            beam_width: "Beam Width",
            anchor_spacing: "Anchor Spacing"
          }
        }
      },
      shared: {
        fail: "Fail",
        pass: "Pass",
        not_applicable: "Not Applicable",
        comment: "Comment"
      }
    })
  end

  def render_number_pass_fail_na_comment(locals = {})
    partial_name = "form/number_pass_fail_na_comment"
    render partial: partial_name, locals: {field:}.merge(locals)
  end

  # Helper methods for common expectations using Capybara selectors
  def expect_basic_structure
    expect(rendered).to have_css(form_grid_selector)
    expect(rendered).to have_content(field_label)
  end

  def expect_number_input
    expect(rendered).to have_field(type: "number")
  end

  def expect_pass_fail_radios
    expect(rendered).to have_content(pass_label)
    expect(rendered).to have_content(fail_label)
    expect(rendered).to have_css('input[type="radio"][value="pass"]')
    expect(rendered).to have_css('input[type="radio"][value="fail"]')
  end

  def expect_na_radio
    expect(rendered).to have_content(na_label)
    expect(rendered).to have_field("Not Applicable", type: "radio")
  end

  def expect_comment_section
    expect(rendered).to have_content(comment_label)
    expect(rendered).to have_field(type: "textarea", visible: :all)
  end

  def expect_na_radio_checked
    expect(rendered).to have_checked_field("Not Applicable", type: "radio")
  end

  def expect_na_radio_unchecked
    expect(rendered).to have_unchecked_field("Not Applicable", type: "radio")
  end

  def expect_no_radio_checked
    expect(rendered).not_to have_checked_field(type: "radio")
  end

  def expect_radio_value_checked(value)
    selector = "input[type=\"radio\"][value=\"#{value}\"][checked]"
    expect(rendered).to have_css(selector)
  end

  def expect_radio_value_not_checked(value)
    selector = "input[type=\"radio\"][value=\"#{value}\"][checked]"
    expect(rendered).not_to have_css(selector)
  end

  def expect_na_not_checked
    expect(rendered).not_to have_checked_field("Not Applicable", type: "radio")
  end

  describe "number field options" do
    it "accepts custom step value" do
      render_number_pass_fail_na_comment(step: 0.01)

      expect(rendered).to have_css('input[type="number"][step="0.01"]')
    end

    it "accepts min and max values" do
      render_number_pass_fail_na_comment(min: 0, max: 100)

      expect(rendered).to have_css('input[type="number"][min="0"][max="100"]')
    end

    it "accepts required attribute" do
      render_number_pass_fail_na_comment(required: true)

      expect(rendered).to have_css('input[type="number"][required]')
    end
  end

  describe "comment functionality" do
    it "shows comment checkbox when field has existing comment" do
      test_model.slide_platform_height_comment = "Test comment"

      render_number_pass_fail_na_comment

      selector = 'input[type="checkbox"][data-comment-toggle][checked]'
      expect(rendered).to have_css(selector)
    end
  end

  describe "different field contexts" do
    shared_examples "renders correctly for field" do |field_name, expected_label|
      it "handles #{field_name} field" do
        view.form_with(model: test_model, url: "/", local: true) do |f|
          @_current_form = f
          ""
        end

        partial_name = "form/number_pass_fail_na_comment"
        render partial: partial_name, locals: {field: field_name}

        grid_selector = "div.form-grid.number-radio-comment"
        expect(rendered).to have_css(grid_selector)
        expect(rendered).to have_css("label.label", text: expected_label)

        # Number field
        number_selector = "input[type=\"number\"][name*=\"#{field_name}\"]"
        expect(rendered).to have_css(number_selector)

        # Pass/fail field
        pass_field = "#{field_name}_pass"
        radio_selector = "input[type=\"radio\"][name*=\"#{pass_field}\"]"
        expect(rendered).to have_css(radio_selector)

        # N/A radio button
        expect(rendered).to have_field("Not Applicable", type: "radio")

        # Comment field
        comment_field = "#{field_name}_comment"
        comment_selector = "textarea[name*=\"#{comment_field}\"]"
        expect(rendered).to have_css(comment_selector, visible: :all)
      end
    end

    include_examples "renders correctly for field", :beam_width, "Beam Width"
    include_examples "renders correctly for field", :anchor_spacing,
      "Anchor Spacing"
  end

  describe "i18n integration" do
    it "uses i18n for all labels" do
      render_number_pass_fail_na_comment

      expect(rendered).to have_content("Pass")
      expect(rendered).to have_content("Fail")
      expect(rendered).to have_content("Not Applicable")
      expect(rendered).to have_content("Comment")
    end

    it "uses correct field label from i18n" do
      render_number_pass_fail_na_comment

      expect(rendered).to have_css("label.label", text: "Slide Platform Height")
    end
  end
end
