# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorsController, type: :request do
  describe "GET /404 (not_found)" do
    context "when requesting HTML format" do
      it "renders the 404 page without requiring authentication" do
        get "/404"

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include(I18n.t("errors.not_found.title"))
        expect(response.body).to include(I18n.t("errors.not_found.message"))
      end
    end

    context "when requesting JSON format" do
      it "returns JSON error response" do
        get "/404", headers: {"Accept" => "application/json"}

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to match(/application\/json/)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq(I18n.t("errors.not_found.title"))
      end
    end

    context "when requesting other formats" do
      it "returns only status code for XML format" do
        get "/404", headers: {"Accept" => "application/xml"}

        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_blank
      end

      it "returns only status code for text format" do
        get "/404", headers: {"Accept" => "text/plain"}

        expect(response).to have_http_status(:not_found)
        expect(response.body).to be_blank
      end
    end
  end

  describe "GET /500 (internal_server_error)" do
    context "when requesting HTML format" do
      it "renders the 500 page without requiring authentication" do
        get "/500"

        expect(response).to have_http_status(:internal_server_error)
        # Check that the error view is rendered (content is inside <main> tag)
        expect(response.body).to include("<main>")
        expect(response.body).to include(I18n.t("errors.internal_server_error.title"))
        # The message might be escaped in HTML, so just check for key parts
        expect(response.body).to match(/something went wrong/i)
      end
    end

    context "when requesting JSON format" do
      it "returns JSON error response" do
        get "/500", headers: {"Accept" => "application/json"}

        expect(response).to have_http_status(:internal_server_error)
        expect(response.content_type).to match(/application\/json/)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq(I18n.t("errors.internal_server_error.title"))
      end
    end

    context "when requesting other formats" do
      it "returns only status code for XML format" do
        get "/500", headers: {"Accept" => "application/xml"}

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to be_blank
      end

      it "returns only status code for text format" do
        get "/500", headers: {"Accept" => "text/plain"}

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to be_blank
      end
    end
  end

  describe "private methods" do
    let(:controller) { ErrorsController.new }

    describe "#capture_exception_for_sentry" do
      context "when in production environment" do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
          allow(Sentry).to receive(:capture_exception)
        end

        it "captures exception when present in request env" do
          exception = StandardError.new("Test exception")
          request = double(env: {"action_dispatch.exception" => exception})
          allow(controller).to receive(:request).and_return(request)

          controller.send(:capture_exception_for_sentry)

          expect(Sentry).to have_received(:capture_exception).with(exception)
        end

        it "does not capture when no exception in request env" do
          request = double(env: {})
          allow(controller).to receive(:request).and_return(request)

          controller.send(:capture_exception_for_sentry)

          expect(Sentry).not_to have_received(:capture_exception)
        end
      end

      context "when not in production environment" do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
          allow(Sentry).to receive(:capture_exception)
        end

        it "does not capture exception even when present" do
          exception = StandardError.new("Test exception")
          request = double(env: {"action_dispatch.exception" => exception})
          allow(controller).to receive(:request).and_return(request)

          controller.send(:capture_exception_for_sentry)

          expect(Sentry).not_to have_received(:capture_exception)
        end
      end
    end
  end
end
