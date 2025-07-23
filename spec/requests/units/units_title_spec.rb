require "rails_helper"

RSpec.describe "Units Index Title", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "page title construction" do
    it "shows only base title when no filters are applied" do
      get units_path

      expect(response.body).to include("<h1>#{I18n.t("units.titles.index")}</h1>")
      expect(response.body).not_to include("<h1>#{I18n.t("units.titles.index")} - </h1>")
    end

    it "includes overdue status in title when filtered" do
      get units_path(status: "overdue")

      expected_title = "#{I18n.t("units.titles.index")} - #{I18n.t("units.status.overdue")}"
      expect(response.body).to include("<h1>#{expected_title}</h1>")
    end

    it "includes manufacturer in title when filtered" do
      get units_path(manufacturer: "Airquee Ltd")

      expected_title = "#{I18n.t("units.titles.index")} - Airquee Ltd"
      expect(response.body).to include("<h1>#{expected_title}</h1>")
    end

    it "includes operator in title when filtered" do
      get units_path(operator: "Stef's Rentals")

      expect(response.body).to include("<h1>Units - Stef&#39;s Rentals</h1>")
    end

    it "combines multiple filters in title" do
      get units_path(status: "overdue", manufacturer: "Bouncy Co", operator: "John's Events")

      expect(response.body).to include("<h1>Units - Overdue - Bouncy Co - John&#39;s Events</h1>")
    end

    it "ignores empty string parameters" do
      get units_path(manufacturer: "", operator: "")

      expect(response.body).to include("<h1>#{I18n.t("units.titles.index")}</h1>")
      expect(response.body).not_to include(" - ")
    end

    it "ignores nil parameters" do
      get units_path(manufacturer: nil, operator: nil)

      expect(response.body).to include("<h1>#{I18n.t("units.titles.index")}</h1>")
      expect(response.body).not_to include(" - ")
    end
  end
end
