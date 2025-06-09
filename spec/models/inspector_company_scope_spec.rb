require "rails_helper"

RSpec.describe InspectorCompany, type: :model do
  describe "scopes" do
    let!(:active_company) { create(:inspector_company, name: "Active Company", active: true) }
    let!(:archived_company) { create(:inspector_company, name: "Archived Company", active: false) }

    before do
      # Clean up any other inspector companies to ensure test isolation
      InspectorCompany.where.not(id: [active_company.id, archived_company.id]).destroy_all
    end

    describe ".by_status" do
      it "returns all companies when status is 'all'" do
        result = InspectorCompany.by_status("all")
        expect(result.count).to eq(2)
        expect(result).to include(active_company, archived_company)
      end

      it "returns all companies when status is nil" do
        result = InspectorCompany.by_status(nil)
        expect(result.count).to eq(2) # Should default to all companies
        expect(result).to include(active_company, archived_company)
      end

      it "returns only active companies when status is 'active'" do
        result = InspectorCompany.by_status("active")
        expect(result.count).to eq(1)
        expect(result).to include(active_company)
        expect(result).not_to include(archived_company)
      end

      it "returns only archived companies when status is 'archived'" do
        result = InspectorCompany.by_status("archived")
        expect(result.count).to eq(1)
        expect(result).to include(archived_company)
        expect(result).not_to include(active_company)
      end

      it "defaults to all companies when status is anything else" do
        result = InspectorCompany.by_status("invalid")
        expect(result.count).to eq(2)
        expect(result).to include(active_company, archived_company)
      end
    end

    describe "controller integration" do
      it "simulates the controller chain with 'all'" do
        # This simulates what the controller does:
        # InspectorCompany.by_status(params[:active]).search_by_term(params[:search]).order(:name)
        result = InspectorCompany
          .by_status("all")
          .search_by_term(nil)
          .order(:name)

        expect(result.count).to eq(2)
        expect(result.pluck(:name)).to eq(["Active Company", "Archived Company"])
      end
    end
  end
end
