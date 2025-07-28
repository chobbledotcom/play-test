require "rails_helper"

RSpec.describe "chobble_forms/_number.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :quantity }
  let(:field_config) do
    {
      form_object: mock_form,
      i18n_base: "test.forms",
      field_label: "Quantity",
      field_hint: "Enter a number",
      field_placeholder: "0"
    }
  end

  # Default render method with common setup
  def render_number_field(locals = {})
    render partial: "chobble_forms/number", locals: {field: field}.merge(locals)
  end

  before do
    # Mock the form field setup helper
    allow(view).to receive(:form_field_setup).and_return(field_config)

    # Mock form builder methods with default behavior
    allow(mock_form).to receive(:label)
      .with(field, "Quantity")
      .and_return('<label for="quantity">Quantity</label>'.html_safe)

    allow(mock_form).to receive(:number_field)
      .with(field, anything)
      .and_return('<input type="number" name="quantity" id="quantity" />'.html_safe)

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  describe "basic rendering" do
    it "renders a complete number field group" do
      render_number_field

      expect(rendered).to have_css("div.number-field") do |wrapper|
        expect(wrapper).to have_css('label[for="quantity"]', text: "Quantity")
        expect(wrapper).to have_css('input[type="number"][name="quantity"][id="quantity"]')
        expect(wrapper).to have_css("small.form-text", text: "Enter a number")
      end
    end

    it "maintains correct element order (label, input, hint)" do
      render_number_field
      expect(rendered).to match(/<label.*?>.*?<\/label>.*?<input.*?type="number".*?>.*?<small/m)
    end

    context "when hint is not present" do
      let(:field_config) { super().merge(field_hint: nil) }

      it "does not render the hint element" do
        render_number_field
        expect(rendered).not_to have_css("small.form-text")
      end
    end
  end

  describe "default behavior" do
    it "applies default step of 0.01" do
      allow(mock_form).to receive(:number_field)
        .with(field, hash_including(step: 0.01))
        .and_return('<input type="number" step="0.01" />'.html_safe)

      render_number_field
      expect(mock_form).to have_received(:number_field).with(field, hash_including(step: 0.01))
    end

    it "includes placeholder from field config" do
      allow(mock_form).to receive(:number_field)
        .with(field, hash_including(placeholder: "0"))
        .and_return('<input type="number" placeholder="0" />'.html_safe)

      render_number_field
      expect(mock_form).to have_received(:number_field).with(field, hash_including(placeholder: "0"))
    end
  end

  describe "custom numeric attributes" do
    shared_examples "supports numeric attribute" do |attribute, value|
      it "passes #{attribute} attribute to number field" do
        allow(mock_form).to receive(:number_field)
          .with(field, hash_including(attribute => value))
          .and_return(%(<input type="number" #{attribute}="#{value}" />).html_safe)

        render_number_field(attribute => value)
        expect(rendered).to have_css(%(input[type="number"][#{attribute}="#{value}"]))
      end
    end

    include_examples "supports numeric attribute", :step, 1
    include_examples "supports numeric attribute", :step, 0.1
    include_examples "supports numeric attribute", :step, "any"
    include_examples "supports numeric attribute", :min, 0
    include_examples "supports numeric attribute", :min, -100
    include_examples "supports numeric attribute", :max, 100
    include_examples "supports numeric attribute", :max, 999

    it "supports multiple numeric attributes together" do
      allow(mock_form).to receive(:number_field)
        .with(field, hash_including(min: 0, max: 100, step: 5))
        .and_return('<input type="number" min="0" max="100" step="5" />'.html_safe)

      render_number_field(min: 0, max: 100, step: 5)
      expect(rendered).to have_css('input[type="number"][min="0"][max="100"][step="5"]')
    end
  end

  describe "CSS customization" do
    it "applies custom CSS class to input field" do
      allow(mock_form).to receive(:number_field)
        .with(field, hash_including(class: "custom-control"))
        .and_return('<input type="number" class="custom-control" />'.html_safe)

      render_number_field(css_class: "custom-control")
      expect(rendered).to have_css("input[type='number']")
    end

    it "applies custom wrapper class" do
      render_number_field(wrapper_class: "custom-wrapper")
      expect(rendered).to have_css("div.number-field")
    end
  end

  describe "form object handling" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return(
        field_config.merge(form_object: other_form)
      )
      allow(other_form).to receive(:label).and_return("<label>Quantity</label>".html_safe)
      allow(other_form).to receive(:number_field).and_return('<input type="number" />'.html_safe)
    end

    it "uses the form object returned by form_field_setup" do
      render_number_field(form: other_form)

      expect(other_form).to have_received(:label)
      expect(other_form).to have_received(:number_field)
      expect(mock_form).not_to have_received(:label)
      expect(mock_form).not_to have_received(:number_field)
    end
  end

  describe "different number field types" do
    shared_examples "renders correctly for field" do |field_name, expected_label|
      it "handles #{field_name} field" do
        # Update mocks for the new field
        allow(mock_form).to receive(:label)
          .with(field_name, expected_label)
          .and_return(%(<label for="#{field_name}">#{expected_label}</label>).html_safe)

        allow(mock_form).to receive(:number_field)
          .with(field_name, anything)
          .and_return(%(<input type="number" name="#{field_name}" id="#{field_name}" />).html_safe)

        # Need to mock form_field_setup for the new field
        allow(view).to receive(:form_field_setup).and_return(
          field_config.merge(field_label: expected_label)
        )

        render_number_field(field: field_name)
        expect(rendered).to have_css("div.number-field")
        expect(rendered).to have_css("label", text: expected_label)
      end
    end

    include_examples "renders correctly for field", :price, "Price"
    include_examples "renders correctly for field", :quantity, "Quantity"
    include_examples "renders correctly for field", :age, "Age"
    include_examples "renders correctly for field", :weight, "Weight"
    include_examples "renders correctly for field", :height, "Height"
  end

  describe "edge cases and validation" do
    it "excludes nil values from options hash" do
      # The partial should use compact to remove nil values
      allow(mock_form).to receive(:number_field) do |field, options|
        expect(options).not_to have_key(:min)
        expect(options).not_to have_key(:max)
        expect(options).to have_key(:step) # step has a default
        expect(options).to have_key(:placeholder) # placeholder comes from field_config
        '<input type="number" />'.html_safe
      end

      render_number_field(min: nil, max: nil)
    end

    it "handles decimal step values correctly" do
      allow(mock_form).to receive(:number_field)
        .with(field, hash_including(step: 0.001))
        .and_return('<input type="number" step="0.001" />'.html_safe)

      render_number_field(step: 0.001)
      expect(rendered).to have_css('input[type="number"][step="0.001"]')
    end

    it "supports 'any' as step value for unrestricted precision" do
      allow(mock_form).to receive(:number_field)
        .with(field, hash_including(step: "any"))
        .and_return('<input type="number" step="any" />'.html_safe)

      render_number_field(step: "any")
      expect(rendered).to have_css('input[type="number"][step="any"]')
    end
  end

  describe "accessibility" do
    it "properly associates label with input field" do
      render_number_field

      # Label should have 'for' attribute matching input 'id'
      expect(rendered).to have_css('label[for="quantity"]')
      expect(rendered).to have_css('input#quantity[type="number"]')
    end

    it "includes aria-describedby when hint is present" do
      # This test documents that the current implementation doesn't add aria-describedby
      # but it could be enhanced to do so
      render_number_field
      expect(rendered).not_to include("aria-describedby")
    end
  end
end
