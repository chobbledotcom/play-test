require "rails_helper"

RSpec.describe "Units Filtering", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "GET /units with filters" do
    # Create base units with default serials
    let!(:base_airquee_unit) { create(:unit, user: user, name: "Airquee Castle", manufacturer: "Airquee Ltd", operator: "Operator A") }
    let!(:base_bouncy_unit) { create(:unit, user: user, name: "Bouncy Castle", manufacturer: "Bouncy Co", operator: "Operator B") }
    let!(:base_other_unit) { create(:unit, user: user, name: "Other Castle", manufacturer: "Other Brand", operator: "Operator C") }

    context "when filtering by manufacturer" do
      it "shows only units from the selected manufacturer" do
        get units_path(manufacturer: "Airquee Ltd")

        expect(response.body).to include("Airquee Castle")
        expect(response.body).not_to include("Bouncy Castle")
        expect(response.body).not_to include("Other Castle")
      end

      it "shows all units when manufacturer filter is empty string" do
        get units_path(manufacturer: "")

        expect(response.body).to include("Airquee Castle")
        expect(response.body).to include("Bouncy Castle")
        expect(response.body).to include("Other Castle")
      end
    end

    context "when filtering by operator" do
      it "shows only units from the selected operator" do
        get units_path(operator: "Operator B")

        expect(response.body).not_to include("Airquee Castle")
        expect(response.body).to include("Bouncy Castle")
        expect(response.body).not_to include("Other Castle")
      end

      it "shows all units when operator filter is empty string" do
        get units_path(operator: "")

        expect(response.body).to include("Airquee Castle")
        expect(response.body).to include("Bouncy Castle")
        expect(response.body).to include("Other Castle")
      end
    end

    context "when combining filters" do
      let!(:airquee_operatorb) { create(:unit, user: user, name: "Airquee B", manufacturer: "Airquee Ltd", operator: "Operator B") }

      it "applies both filters" do
        get units_path(manufacturer: "Airquee Ltd", operator: "Operator B")

        expect(response.body).to include("Airquee B")
        expect(response.body).not_to include("Airquee Castle")
        expect(response.body).not_to include("Bouncy Castle")
        expect(response.body).not_to include("Other Castle")
      end
    end

    context "when filtering by status" do
      let!(:current_unit) { create(:unit, user: user, name: "Current Unit") }
      let!(:overdue_unit) { create(:unit, user: user, name: "Overdue Unit") }

      before do
        # Create an old inspection for the overdue unit
        create(:inspection, :completed,
          user: user,
          unit: overdue_unit,
          inspection_date: (EN14960::Constants::REINSPECTION_INTERVAL_DAYS + 10).days.ago)

        # Create a recent inspection for the current unit
        create(:inspection, :completed,
          user: user,
          unit: current_unit,
          inspection_date: 10.days.ago)
      end

      it "shows only overdue units when status is overdue" do
        get units_path(status: "overdue")

        expect(response.body).to include("Overdue Unit")
        expect(response.body).not_to include("Current Unit")
      end
    end

    context "when searching" do
      before do
        # Create units with specific serials for search tests
        create(:unit, user: user, name: "Search Airquee", serial: "AIR-2024-001", manufacturer: "Test", operator: "Test")
        create(:unit, user: user, name: "Search Bouncy", serial: "BCY-2024-002", manufacturer: "Test", operator: "Test")
        create(:unit, user: user, name: "Search Other", serial: "OTH-2024-003", manufacturer: "Test", operator: "Test")
      end

      it "finds units by serial number" do
        get units_path(query: "AIR-2024")

        expect(response.body).to include("Search Airquee")
        expect(response.body).not_to include("Search Bouncy")
        expect(response.body).not_to include("Search Other")
      end

      it "finds units by name" do
        get units_path(query: "Search Bouncy")

        expect(response.body).not_to include("Search Airquee")
        expect(response.body).to include("Search Bouncy")
        expect(response.body).not_to include("Search Other")
      end
    end
  end
end
