require "rails_helper"

RSpec.describe "inspector_companies/edit", type: :view do
  let(:inspector_company) { create(:inspector_company) }

  before do
    assign(:inspector_company, inspector_company)
    setup_admin_view_context
  end

  it "renders edit inspector company form" do
    render

    expect_i18n_content("inspector_companies.titles.edit")
  end

  it "pre-populates form fields with existing data" do
    render

    expect_model_attributes_displayed(inspector_company, :name, :email, :phone,
      :address, :city, :postal_code)
  end

  it "shows form for boolean fields" do
    render

    expect_form_field("inspector_company[active]", type: "checkbox")
  end

  it "includes form elements" do
    render

    expect_submit_button("forms.inspector_companies")
  end

  it "includes admin-only notes field" do
    inspector_company.update!(notes: "Existing notes")
    render

    expect_i18n_content("forms.inspector_companies.fields.notes")
    expect(rendered).to have_field("inspector_company[notes]", with: "Existing notes")
  end

  context "when company has existing logo" do
    before do
      # Mock the logo attachment
      logo_attachment = double("logo_attachment")
      allow(logo_attachment).to receive(:attached?).and_return(true)
      allow(logo_attachment).to receive(:image?).and_return(true)
      allow(logo_attachment).to receive(:filename).and_return("logo.png")

      # Mock for the image rendering
      blob = double("blob")
      allow(logo_attachment).to receive(:blob).and_return(blob)
      allow(blob).to receive(:persisted?).and_return(true)

      allow(inspector_company).to receive(:logo).and_return(logo_attachment)
      allow(ImageProcessorService).to receive(:thumbnail).and_return("processed_image_url")

      # Mock image_tag to avoid asset pipeline issues in tests
      allow(view).to receive(:image_tag).and_return('<img src="test-logo.jpg" alt="Current logo">'.html_safe)
    end

    it "shows current logo preview" do
      render

      expect(rendered).to include("Current logo")
      expect(rendered).to include("file-preview")
      expect(rendered).to include('<img src="test-logo.jpg"')
    end
  end
end
