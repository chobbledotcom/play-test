# typed: false

require "rails_helper"

RSpec.describe "inspector_companies/show", type: :view do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  let(:inspector_company) { create(:inspector_company) }

  let(:company_stats) do
    {
      total_inspections: 10,
      passed_inspections: 8,
      failed_inspections: 2,
      pass_rate: 80.0,
      active_since: 2023,
      verified: true
    }
  end

  let(:recent_inspections) { [] }

  before do
    assign(:inspector_company, inspector_company)
    assign(:company_stats, company_stats)
    assign(:recent_inspections, recent_inspections)
  end

  context "when user is admin" do
    before do
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it "renders company information" do
      render

      expect(rendered).to include(inspector_company.name)
      expect(rendered).to include(inspector_company.email)
      expect(rendered).to include(inspector_company.phone)
      expect(rendered).to include("UK")
    end

    # Credentials are now validated at the inspector level, not company level

    it "shows admin action links" do
      render

      expect(rendered).to include("Edit")
    end

    it "displays company statistics" do
      render

      expect(rendered).to include("10") # total inspections
      expect(rendered).to include("8")  # passed inspections
      expect(rendered).to include("2")  # failed inspections
      expect(rendered).to include("80.0%") # pass rate
      expect(rendered).to include("2023") # active since
    end

    it "shows notes field and content when present" do
      inspector_company.update!(notes: "Test admin notes")
      render

      expect(rendered).to have_content(I18n.t("inspector_companies.forms.notes"))
      expect(rendered).to include("Test admin notes")
    end

    it "does not show notes section when notes are empty" do
      inspector_company.update!(notes: "")
      render

      expect(rendered).not_to have_content(I18n.t("inspector_companies.forms.notes"))
    end
  end

  context "when user is regular user" do
    before do
      allow(view).to receive(:current_user).and_return(regular_user)
    end

    it "renders company information without admin actions" do
      render

      expect(rendered).to include(inspector_company.name)
      expect(rendered).not_to include("Edit")
      expect(rendered).not_to include("Archive")
    end

    it "does not show notes field even when notes are present" do
      inspector_company.update!(notes: "Secret admin notes")
      render

      expect(rendered).not_to have_content(I18n.t("inspector_companies.forms.notes"))
      expect(rendered).not_to include("Secret admin notes")
    end

    it "does not show notes field when notes are empty" do
      inspector_company.update!(notes: "")
      render

      expect(rendered).not_to have_content(I18n.t("inspector_companies.forms.notes"))
    end
  end

  context "when company has recent inspections" do
    let(:test_unit) { create(:unit, user: admin_user, serial: "TEST001") }
    let(:recent_inspections) do
      [
        create(:inspection,
          user: admin_user,
          unit: test_unit,
          inspector_company: inspector_company,
          **SeedData.inspection_fields)
      ]
    end

    before do
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it "displays recent inspections" do
      render

      expect(rendered).to include("Recent Inspections")
      expect(rendered).to include("TEST001")
      expect(rendered).to include("TEST001") # Unit serial instead of location
      expect(rendered).to include("Pass") # passed
    end
  end

  context "when company has no recent inspections" do
    before do
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it "shows no inspections message" do
      render

      expect(rendered).to include("No inspections recorded yet")
    end
  end

  context "when company has no email" do
    before do
      inspector_company.update!(email: nil)
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it "shows not provided for missing email" do
      render

      expect(rendered).to include("Not provided")
    end
  end
end
