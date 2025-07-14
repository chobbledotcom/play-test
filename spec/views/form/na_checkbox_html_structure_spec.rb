require "rails_helper"

RSpec.describe "N/A Checkbox HTML Structure for JavaScript", type: :view do
  let(:test_model) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :safety_check_pass, :safety_check_comment
      def persisted? = false

      def model_name = ActiveModel::Name.new(self.class, nil, "test_model")

      # Mock enum behavior for _pass fields to support N/A radio buttons
      def self.defined_enums
        {"safety_check_pass" => {"fail" => 0, "pass" => 1, "na" => 2}}
      end
    end.new
  end

  before do
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
            safety_check_pass: "Safety Check"
          }
        }
      },
      shared: {
        pass: "Pass",
        fail: "Fail",
        not_applicable: "Not Applicable",
        comment: "Comment",
        field_comment_placeholder: "%{field} comment"
      }
    })
  end

  it "generates HTML structure with radio buttons for pass/fail/N/A behavior" do
    render partial: "form/pass_fail_na_comment", locals: {field: :safety_check_pass}

    # All options should be radio buttons now
    expect(rendered).to have_css('input[type="radio"][value="pass"]')
    expect(rendered).to have_css('input[type="radio"][value="fail"]')
    expect(rendered).to have_css('input[type="radio"][value="na"]')

    # All radios should have the same name for mutual exclusivity
    expect(rendered).to have_css('input[type="radio"][name*="safety_check_pass"]')
  end

  it "Pass radio is checked when field value is pass" do
    test_model.safety_check_pass = "pass"

    render partial: "form/pass_fail_na_comment", locals: {field: :safety_check_pass}

    expect(rendered).to have_checked_field("Pass", type: "radio")
  end

  it "N/A radio is checked when field value is na" do
    test_model.safety_check_pass = "na"

    render partial: "form/pass_fail_na_comment", locals: {field: :safety_check_pass}

    expect(rendered).to have_checked_field("Not Applicable", type: "radio")
  end

  it "provides semantic labels that JavaScript can interact with" do
    render partial: "form/pass_fail_na_comment", locals: {field: :safety_check_pass}

    # These labels allow users (and tests) to interact semantically
    expect(rendered).to have_content("Pass")
    expect(rendered).to have_content("Fail")
    expect(rendered).to have_content("Not Applicable")

    # JavaScript can find these by content, not just by complex selectors
    doc = Nokogiri::HTML(rendered)

    # Find labels that contain the text (accounting for whitespace and nested elements)
    pass_label = doc.xpath("//label[contains(normalize-space(text()), 'Pass')]").first
    fail_label = doc.xpath("//label[contains(normalize-space(.), 'Fail') and input[@type='radio']]").first
    na_label = doc.xpath("//label[contains(normalize-space(.), 'Not Applicable')]").first

    expect(pass_label).not_to be_nil
    expect(fail_label).not_to be_nil
    expect(na_label).not_to be_nil

    # Each label should contain radio inputs with enum values
    expect(pass_label.css('input[type="radio"][value="pass"]')).not_to be_empty
    expect(fail_label.css('input[type="radio"][value="fail"]')).not_to be_empty
    expect(na_label.css('input[type="radio"][value="na"]')).not_to be_empty
  end
end
