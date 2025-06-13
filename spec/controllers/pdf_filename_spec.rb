require "rails_helper"

RSpec.describe "PDF Content Changes", type: :request do
  describe "Serial Number label" do
    it "shows 'Serial Number' instead of 'Serial Number / Asset ID'" do
      expect(I18n.t("pdf.inspection.fields.serial")).to eq("Serial Number")
    end
  end
end
