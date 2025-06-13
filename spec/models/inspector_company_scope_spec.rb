require "rails_helper"

RSpec.describe InspectorCompany, type: :model do
  describe "scopes" do
    let!(:active_company) { create(:inspector_company, name: "Active Company", active: true) }
    let!(:archived_company) { create(:inspector_company, name: "Archived Company", active: false) }


    describe ".by_status" do
      it "returns all companies when status is 'all'" do
        result = InspectorCompany.by_status("all")
        expect(result).to include(active_company, archived_company)
      end

      it "returns all companies when status is nil" do
        result = InspectorCompany.by_status(nil)
        expect(result).to include(active_company, archived_company)
      end

      it "returns only active companies when status is 'active'" do
        result = InspectorCompany.by_status("active")
        expect(result).to include(active_company)
        expect(result).not_to include(archived_company)
      end

      it "returns only archived companies when status is 'archived'" do
        result = InspectorCompany.by_status("archived")
        expect(result).to include(archived_company)
        expect(result).not_to include(active_company)
      end

      it "defaults to all companies when status is anything else" do
        result = InspectorCompany.by_status("invalid")
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

        expect(result).to include(active_company, archived_company)
        
        # Check that our test companies appear in alphabetical order
        company_names = result.pluck(:name)
        expect(company_names).to include("Active Company", "Archived Company")
        active_index = company_names.index("Active Company")
        archived_index = company_names.index("Archived Company")
        expect(active_index).to be < archived_index
      end
    end
  end
end
