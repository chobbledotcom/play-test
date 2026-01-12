# typed: false

require "rails_helper"

RSpec.describe "Units Index Title", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe "page title construction" do
    it "shows only base title when no filters are applied" do
      get units_path

      title = I18n.t("units.titles.index")
      expect(response.body).to include("<h1>#{title}</h1>")
      expect(response.body).not_to include("<h1>#{title} - </h1>")
    end

    it "includes overdue status in title when filtered" do
      get units_path(status: "overdue")

      title = I18n.t("units.titles.index")
      status = I18n.t("units.status.overdue")
      expect(response.body).to include("<h1>#{title} - #{status}</h1>")
    end

    it "includes manufacturer in title when filtered" do
      get units_path(manufacturer: "Airquee Ltd")

      title = I18n.t("units.titles.index")
      expect(response.body).to include("<h1>#{title} - Airquee Ltd</h1>")
    end

    it "combines multiple filters in title" do
      get units_path(status: "overdue", manufacturer: "Bouncy Co")

      expect(response.body).to include("<h1>Units - Overdue - Bouncy Co</h1>")
    end

    it "ignores empty string parameters" do
      get units_path(manufacturer: "")

      title = I18n.t("units.titles.index")
      expect(response.body).to include("<h1>#{title}</h1>")
      expect(response.body).not_to include(" - ")
    end

    it "ignores nil parameters" do
      get units_path(manufacturer: nil)

      title = I18n.t("units.titles.index")
      expect(response.body).to include("<h1>#{title}</h1>")
      expect(response.body).not_to include(" - ")
    end
  end
end
