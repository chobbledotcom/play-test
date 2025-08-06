# typed: false

require "rails_helper"

RSpec.describe "Prosopite N+1 detection in development", type: :model do
  context "when in development environment" do
    before do
      allow(Rails.env).to receive(:development?).and_return(true)
      # Reload Prosopite configuration to apply development settings
      load Rails.root.join("config/initializers/prosopite.rb")
    end

    after do
      # Reset to test environment behavior
      allow(Rails.env).to receive(:development?).and_return(false)
      Prosopite.raise = false
    end

    it "raises an error when N+1 queries are detected" do
      # Create test data with inspection companies
      companies = 3.times.map { create(:inspector_company) }
      users = companies.map do |company|
        create(:user, inspection_company: company)
      end

      expect {
        ApplicationController.new.send(:n_plus_one_detection) do
          # This intentionally causes N+1 by not including :inspection_company
          User.where(id: users.map(&:id)).each do |user|
            user.inspection_company.name if user.inspection_company
          end
        end
      }.to raise_error(Prosopite::NPlusOneQueriesError)
    end

    it "does not raise when associations are properly included" do
      companies = 3.times.map { create(:inspector_company) }
      users = companies.map do |company|
        create(:user, inspection_company: company)
      end

      expect {
        ApplicationController.new.send(:n_plus_one_detection) do
          # Properly includes the association to avoid N+1
          loaded_users = User.includes(:inspection_company)
            .where(id: users.map(&:id))
          loaded_users.each do |user|
            user.inspection_company.name if user.inspection_company
          end
        end
      }.not_to raise_error
    end
  end

  context "when not in development environment" do
    before do
      allow(Rails.env).to receive(:development?).and_return(false)
      Prosopite.raise = false
    end

    it "does not raise errors for N+1 queries" do
      companies = 3.times.map { create(:inspector_company) }
      users = companies.map do |company|
        create(:user, inspection_company: company)
      end

      expect {
        ApplicationController.new.send(:n_plus_one_detection) do
          User.where(id: users.map(&:id)).each do |user|
            user.inspection_company.name if user.inspection_company
          end
        end
      }.not_to raise_error
    end
  end
end
