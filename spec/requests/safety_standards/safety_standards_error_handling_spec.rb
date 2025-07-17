require "rails_helper"

RSpec.describe "Safety Standards Error Handling", type: :request do
  describe "POST /safety_standards with invalid data" do
    let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    shared_examples "error response" do |error_key|
      it "displays errors with proper CSS class" do
        post safety_standards_path, params: params, headers: turbo_headers

        expect(response.body).to include('class="error"')
        expect(response.body).to include(I18n.t("shared.error"))
        expect(response.body).to include(I18n.t("safety_standards.errors.#{error_key}"))
      end
    end

    context "anchor calculations" do
      let(:params) { { calculation: { type: "anchors", length: 0, width: 0, height: 0 } } }
      include_examples "error response", "invalid_dimensions"
    end

    context "slide runout calculations" do
      let(:params) { { calculation: { type: "slide_runout", platform_height: 0 } } }
      include_examples "error response", "invalid_height"
    end

    context "wall height calculations" do
      let(:params) { { calculation: { type: "wall_height", user_height: -1 } } }
      include_examples "error response", "invalid_height"
    end
  end
end
