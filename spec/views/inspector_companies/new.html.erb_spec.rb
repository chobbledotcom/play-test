require "rails_helper"

RSpec.describe "inspector_companies/new", type: :view do
  let(:admin_user) { create(:user, :admin) }

  before do
    assign(:inspector_company, InspectorCompany.new)
    allow(view).to receive(:current_user).and_return(admin_user)
  end

  it "renders new inspector company form" do
    render

    expect(rendered).to include("New Inspector Company")
    expect(rendered).to include('name="inspector_company[name]"')
    # Form no longer includes company-level RPII field
    expect(rendered).to include('name="inspector_company[email]"')
    expect(rendered).to include('name="inspector_company[phone]"')
    expect(rendered).to include('name="inspector_company[address]"')
  end

  it "includes form fields for company details" do
    render

    expect(rendered).to include("Company Name")
    expect(rendered).to include("Email")
    expect(rendered).to include("Phone")
    expect(rendered).to include("Address")
    expect(rendered).to include("City")
    expect(rendered).to include("Postal Code")
    expect(rendered).to include("Country")
  end

  it "includes admin-only fields" do
    render

    expect(rendered).to include("Active")
    expect(rendered).to have_content(I18n.t("inspector_companies.forms.notes"))
    expect(rendered).to have_field("inspector_company[notes]")
  end

  it "includes logo upload field" do
    render

    expect(rendered).to include("Company Logo")
    expect(rendered).to include('type="file"')
    expect(rendered).to include('accept="image/*"')
  end

  it "includes form actions" do
    render

    expect(rendered).to include('type="submit"')
    expect(rendered).to include(I18n.t("forms.inspector_companies.submit"))
  end

  it "sets default country to UK" do
    render

    expect(rendered).to include('value="UK"')
  end

  it "has navigation link back to companies" do
    render

    expect(rendered).to include("Companies")
  end
end
