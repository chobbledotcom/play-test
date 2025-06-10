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

  it "includes archive action" do
    render

    expect(rendered).to include("Archive")
    expect(rendered).to include('data-turbo-confirm="Are you sure')
  end

  context "when company has existing logo" do
    before do
      # Mock the logo attachment
      allow(inspector_company).to receive_message_chain(:logo, :attached?).and_return(true)
      allow(inspector_company).to receive_message_chain(:logo, :filename).and_return("logo.png")
    end

    it "shows current logo information" do
      render

      expect(rendered).to include("Current logo: logo.png")
    end
  end
end
