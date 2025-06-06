require "rails_helper"

RSpec.describe "inspector_companies/index", type: :view do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before do
    assign(:inspector_companies, [
      InspectorCompany.create!(
        user: admin_user,
        name: "First Company",
        rpii_registration_number: "RPII001",
        phone: "1234567890",
        address: "123 First St",
        rpii_verified: true,
        active: true
      ),
      InspectorCompany.create!(
        user: admin_user,
        name: "Second Company",
        rpii_registration_number: "RPII002",
        phone: "1234567891",
        address: "124 Second St",
        rpii_verified: false,
        active: true
      )
    ])
  end

  context "when user is admin" do
    before do
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it "renders a list of inspector companies" do
      render

      expect(rendered).to include("First Company")
      expect(rendered).to include("Second Company")
      expect(rendered).to include("RPII001")
      expect(rendered).to include("RPII002")
    end

    it "shows verification status" do
      render

      expect(rendered).to include("Verified")
      expect(rendered).to include("Not Verified")
    end

    it "shows admin action links" do
      render

      expect(rendered).to include("Edit")
      expect(rendered).to include("Archive")
    end

    it "includes search form" do
      render

      expect(rendered).to include('name="search"')
      expect(rendered).to include('name="verified"')
    end

    it "shows add new company link" do
      render

      expect(rendered).to include("New Company")
    end
  end

  context "when user is regular user" do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
    end

    it "renders company list without admin actions" do
      render

      expect(rendered).to include("First Company")
      expect(rendered).not_to include("Archive")
      expect(rendered).not_to include("Delete")
    end
  end

  context "when no companies exist" do
    before do
      assign(:inspector_companies, [])
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it "shows no companies message" do
      render

      expect(rendered).to include("No inspector companies found")
    end

    it "shows add first company link for admin" do
      render

      expect(rendered).to include("New Company")
    end
  end
end
