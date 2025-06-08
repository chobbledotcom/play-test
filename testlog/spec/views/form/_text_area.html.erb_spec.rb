require "rails_helper"

RSpec.describe "form/_text_area.html.erb", type: :view do
  let(:mock_form) { double("FormBuilder") }
  let(:field) { :description }

  before do
    # Set up form field setup mock
    allow(view).to receive(:form_field_setup).and_return({
      form_object: mock_form,
      i18n_base: "test.forms",
      field_label: "Description",
      field_hint: "Provide details",
      field_placeholder: "Enter description here..."
    })

    # Mock form builder methods
    allow(mock_form).to receive(:label).and_return('<label for="description">Description</label>'.html_safe)
    allow(mock_form).to receive(:text_area).and_return('<textarea name="description" id="description"></textarea>'.html_safe)

    # Set current i18n base for the partial
    view.instance_variable_set(:@_current_i18n_base, "test.forms")
  end

  context "with default options" do
    it "renders text area with label" do
      render partial: "form/text_area", locals: {field: field}

      expect(rendered).to have_css("div.form-group")
      expect(rendered).to include('<label for="description">Description</label>')
      expect(rendered).to include('<textarea name="description" id="description"></textarea>')
    end

    it "displays hint when present" do
      render partial: "form/text_area", locals: {field: field}

      expect(rendered).to have_css("small.form-text", text: "Provide details")
    end

    it "uses default rows of 4" do
      allow(mock_form).to receive(:text_area).with(field, hash_including(rows: 4)).and_return('<textarea rows="4"></textarea>'.html_safe)

      render partial: "form/text_area", locals: {field: field}

      expect(mock_form).to have_received(:text_area).with(field, hash_including(rows: 4))
    end

    it "uses default CSS class" do
      allow(mock_form).to receive(:text_area).with(field, hash_including(class: "form-control")).and_return('<textarea class="form-control"></textarea>'.html_safe)

      render partial: "form/text_area", locals: {field: field}

      expect(mock_form).to have_received(:text_area).with(field, hash_including(class: "form-control"))
    end
  end

  context "with custom options" do
    it "uses custom rows value" do
      allow(mock_form).to receive(:text_area).with(field, hash_including(rows: 5)).and_return('<textarea rows="5"></textarea>'.html_safe)

      render partial: "form/text_area", locals: {field: field, rows: 5}

      expect(mock_form).to have_received(:text_area).with(field, hash_including(rows: 5))
    end

    it "uses custom CSS class" do
      allow(mock_form).to receive(:text_area).with(field, hash_including(class: "custom-textarea")).and_return('<textarea class="custom-textarea"></textarea>'.html_safe)

      render partial: "form/text_area", locals: {field: field, css_class: "custom-textarea"}

      expect(mock_form).to have_received(:text_area).with(field, hash_including(class: "custom-textarea"))
    end

    it "uses custom wrapper class" do
      render partial: "form/text_area", locals: {field: field, wrapper_class: "custom-wrapper"}

      expect(rendered).to have_css("div.custom-wrapper")
    end
  end

  context "with placeholder" do
    it "includes placeholder in field options" do
      allow(mock_form).to receive(:text_area).with(field, hash_including(placeholder: "Enter description here...")).and_return('<textarea placeholder="Enter description here..."></textarea>'.html_safe)

      render partial: "form/text_area", locals: {field: field}

      expect(mock_form).to have_received(:text_area).with(field, hash_including(placeholder: "Enter description here..."))
    end
  end

  context "without hint" do
    before do
      allow(view).to receive(:form_field_setup).and_return({
        form_object: mock_form,
        i18n_base: "test.forms",
        field_label: "Description",
        field_hint: nil,
        field_placeholder: nil
      })
    end

    it "does not render hint element" do
      render partial: "form/text_area", locals: {field: field}

      expect(rendered).not_to have_css("small.form-text")
    end
  end

  context "with explicit form object" do
    let(:other_form) { double("OtherFormBuilder") }

    before do
      allow(view).to receive(:form_field_setup).and_return({
        form_object: other_form,
        i18n_base: "test.forms",
        field_label: "Description",
        field_hint: nil,
        field_placeholder: nil
      })

      allow(other_form).to receive(:label).and_return("<label>Description</label>".html_safe)
      allow(other_form).to receive(:text_area).and_return("<textarea></textarea>".html_safe)
    end

    it "uses provided form object" do
      render partial: "form/text_area", locals: {field: field, form: other_form}

      expect(other_form).to have_received(:label)
      expect(other_form).to have_received(:text_area)
    end
  end

  context "HTML structure" do
    it "has proper semantic structure" do
      render partial: "form/text_area", locals: {field: field}

      expect(rendered).to have_css("div.form-group")
      expect(rendered).to have_css("div.form-group label")
      expect(rendered).to have_css("div.form-group textarea")
      expect(rendered).to have_css("div.form-group small.form-text")
    end

    it "maintains proper nesting order" do
      render partial: "form/text_area", locals: {field: field}

      # Check that label comes before textarea
      expect(rendered).to match(/<label.*<textarea/m)
    end
  end

  context "with different field types" do
    it "handles notes fields" do
      render partial: "form/text_area", locals: {field: :notes}
      expect(rendered).to have_css("div.form-group textarea")
    end

    it "handles comments fields" do
      render partial: "form/text_area", locals: {field: :comments}
      expect(rendered).to have_css("div.form-group textarea")
    end
  end
end
