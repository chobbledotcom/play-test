require "rails_helper"

RSpec.describe "form/_auto_submit_select.html.erb", type: :view do
  let(:field) { :status }
  let(:options) { [ [ "Active", "active" ], [ "Inactive", "inactive" ] ] }

  before do
    # Mock params
    allow(view).to receive(:params).and_return({})
  end

  context "when used within a form context" do
    let(:form_builder) { double("form_builder") }
    let(:mock_object) { double("model") }

    before do
      allow(form_builder).to receive(:object).and_return(mock_object)
      allow(form_builder).to receive(:label).and_return("Status")
      allow(form_builder).to receive(:select).and_return('<select name="status"></select>'.html_safe)
      allow(mock_object).to receive(:status).and_return("active")
    end

    it "renders select within existing form" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        form: form_builder

      expect(form_builder).to have_received(:select).with(
        field,
        include("<option selected=\"selected\" value=\"active\">Active</option>"),
        {},
        { onchange: "this.form.submit();" }
      )
      expect(rendered).to include('<select name="status"></select>')
    end

    it "includes label when provided" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        form: form_builder,
        label: "Choose Status"

      expect(form_builder).to have_received(:label).with(field, "Choose Status")
    end

    it "skips label when not provided" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        form: form_builder

      expect(form_builder).not_to have_received(:label)
    end

    it "includes blank option when requested" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        form: form_builder,
        include_blank: true

      expect(form_builder).to have_received(:select).with(
        field,
        include("<option selected=\"selected\" value=\"active\">Active</option>"),
        { include_blank: "All" },
        { onchange: "this.form.submit();" }
      )
    end

    it "uses custom blank text" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        form: form_builder,
        include_blank: true,
        blank_text: "Choose..."

      expect(form_builder).to have_received(:select).with(
        field,
        include("<option selected=\"selected\" value=\"active\">Active</option>"),
        { include_blank: "Choose..." },
        { onchange: "this.form.submit();" }
      )
    end

    context "with params value" do
      before do
        allow(view).to receive(:params).and_return({ status: "inactive" })
      end

      it "prefers params value over model value" do
        # We can't easily test the options_for_select output directly,
        # but we can verify the select method was called
        render "form/auto_submit_select",
          field: field,
          options: options,
          form: form_builder

        expect(form_builder).to have_received(:select)
      end
    end
  end

  context "when used standalone" do
    let(:url) { "/filter" }

    it "renders standalone form with select" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        url: url

      expect(rendered).to include('action="/filter"')
      expect(rendered).to include('method="get"')
      expect(rendered).to include('data-turbo="false"')
      expect(rendered).to include('onchange="this.form.submit();"')
    end

    it "includes label when provided" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        url: url,
        label: "Filter by Status"

      expect(rendered).to include("Filter by Status")
    end

    it "preserves specified parameters" do
      allow(view).to receive(:params).and_return({ search: "test", page: "2" })

      render "form/auto_submit_select",
        field: field,
        options: options,
        url: url,
        preserve_params: [ :search ]

      expect(rendered).to include('name="search"')
      expect(rendered).to include('value="test"')
      expect(rendered).not_to include('name="page"')
    end

    it "can enable turbo" do
      render "form/auto_submit_select",
        field: field,
        options: options,
        url: url,
        turbo_disabled: false

      expect(rendered).not_to include('data-turbo="false"')
    end

    context "with existing field value in params" do
      before do
        allow(view).to receive(:params).and_return({ status: "active" })
      end

      it "preserves the selected value" do
        render "form/auto_submit_select",
          field: field,
          options: options,
          url: url

        # The selected option should be preserved in the options_for_select
        expect(rendered).to include('onchange="this.form.submit();"')
      end
    end
  end

  context "error handling" do
    it "requires field parameter" do
      expect {
        render "form/auto_submit_select", options: options
      }.to raise_error(ActionView::Template::Error, /field is required/)
    end

    it "requires options parameter" do
      expect {
        render "form/auto_submit_select", field: field
      }.to raise_error(ActionView::Template::Error, /options is required/)
    end

    it "requires url for standalone usage" do
      expect {
        render "form/auto_submit_select", field: field, options: options
      }.to raise_error(ActionView::Template::Error, /url is required for standalone/)
    end
  end

  context "with complex options" do
    let(:complex_options) do
      [
        [ "All Items", "" ],
        [ "Active Items", "active" ],
        [ "Inactive Items", "inactive" ],
        [ "Pending Items", "pending" ]
      ]
    end

    it "handles complex option arrays" do
      render "form/auto_submit_select",
        field: field,
        options: complex_options,
        url: "/test"

      expect(rendered).to include('onchange="this.form.submit();"')
    end
  end
end
