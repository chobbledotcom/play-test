require "rails_helper"

RSpec.describe "inspector_companies/edit", type: :view do
  let(:admin_user) { create(:user, :admin) }

  let(:inspector_company) { create(:inspector_company) }

  before do
    assign(:inspector_company, inspector_company)
    allow(view).to receive(:current_user).and_return(admin_user)
  end

  it "renders edit inspector company form" do
    render

    expect(rendered).to include("Edit Inspector Company")
  end

  it "pre-populates form fields with existing data" do
    render

    expect(rendered).to include(inspector_company.name)
    # RPII numbers are now per-inspector, not per-company
    expect(rendered).to include(inspector_company.email)
    expect(rendered).to include(inspector_company.phone)
    expect(rendered).to include(inspector_company.address)
    expect(rendered).to include(inspector_company.city)
    expect(rendered).to include(inspector_company.postal_code)
  end

  it "shows form for boolean fields" do
    render

    expect(rendered).to include('type="checkbox"')
    expect(rendered).to include('name="inspector_company[active]"')
  end

  it "includes form elements" do
    render

    expect(rendered).to include('type="submit"')
    expect(rendered).to include("Update Company")
  end

  it "includes admin-only notes field" do
    inspector_company.update!(notes: "Existing notes")
    render

    expect(rendered).to have_content(I18n.t("inspector_companies.forms.notes"))
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
