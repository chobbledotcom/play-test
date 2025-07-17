require "rails_helper"

RSpec.describe "form/_search_field.html.erb", type: :view do
  let(:search_url) { "/search" }

  before do
    # Mock params
    allow(view).to receive(:params).and_return({})
  end

  context "with required parameters" do
    it "renders search form with default values" do
      render "form/search_field", url: search_url

      expect(rendered).to include('class="search-form"')
      expect(rendered).to include('action="/search"')
      expect(rendered).to include('method="get"')
      expect(rendered).to include('name="query"')
      expect(rendered).to include('placeholder="Search..."')
      expect(rendered).to include('value="Search"')
    end
  end

  context "with custom parameters" do
    it "uses custom placeholder text" do
      render "form/search_field",
        url: search_url,
        placeholder: "Find units..."

      expect(rendered).to include('placeholder="Find units..."')
    end

    it "uses custom field name" do
      render "form/search_field",
        url: search_url,
        field_name: :search_term

      expect(rendered).to include('name="search_term"')
    end

    it "uses custom submit text" do
      render "form/search_field",
        url: search_url,
        submit_text: "Find"

      expect(rendered).to include('value="Find"')
    end

    it "uses custom CSS class" do
      render "form/search_field",
        url: search_url,
        css_class: "custom-search"

      expect(rendered).to include('class="custom-search"')
    end
  end

  context "with existing search parameters" do
    before do
      allow(view).to receive(:params).and_return({ query: "test search" })
    end

    it "preserves existing search value" do
      render "form/search_field", url: search_url

      expect(rendered).to include('value="test search"')
    end
  end

  context "with custom field name and existing parameters" do
    before do
      allow(view).to receive(:params).and_return({ search_term: "custom search" })
    end

    it "preserves existing value for custom field name" do
      render "form/search_field",
        url: search_url,
        field_name: :search_term

      expect(rendered).to include('value="custom search"')
    end
  end

  context "when url is missing" do
    it "raises an error" do
      expect {
        render "form/search_field"
      }.to raise_error(ActionView::Template::Error, /url is required for search field/)
    end
  end

  context "with complex URL" do
    it "handles URL with path helpers" do
      render "form/search_field", url: search_url + "?type=unit"

      expect(rendered).to include('action="/search?type=unit"')
    end
  end
end
