require "rails_helper"

RSpec.describe "inspector_companies/index", type: :view do
  let(:admin_user) { create(:user, :admin, :without_company) }
  let(:regular_user) { create(:user, :without_company) }

  before do
    assign(:inspector_companies, [
      create(:inspector_company,
        name: "First Company",
        phone: "1234567890",
        address: "123 First St",
        active: true),
      create(:inspector_company,
        name: "Second Company",
        phone: "1234567891",
        address: "124 Second St",
        active: true)
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
      # Companies are displayed with their phone numbers
      expect(rendered).to include("1234567890")
      expect(rendered).to include("1234567891")
    end

    it "shows active status" do
      render

      expect(rendered).to include("Active")
    end

    it "shows admin action links" do
      render

      expect(rendered).to include("Edit")
    end

    it "includes search form" do
      render

      expect(rendered).to include('name="search"')
    end

    it "shows add new company link" do
      render

      expect(rendered).to include("New Company")
    end

    it "shows admin action links for companies" do
      render

      expect(rendered).to include("First Company")
      # Should have admin action links - use Capybara matchers
      expect(rendered).to have_link("Edit")
    end
  end

  context "when user is regular user" do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
    end

    it "renders company list without admin actions" do
      # Ensure the user is not an admin
      expect(regular_user.admin?).to be false

      render

      expect(rendered).to include("First Company")
      # Should not have admin action links - use Capybara matchers
      expect(rendered).not_to have_link("Edit")
      expect(rendered).not_to have_content("Delete")
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
