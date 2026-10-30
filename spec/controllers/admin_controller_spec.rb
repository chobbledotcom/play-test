# typed: false
# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe AdminController, type: :controller do
  let(:admin) { create(:user, :admin) }

  before { allow(controller).to receive(:current_user).and_return(admin) }

  describe "GET #index" do
    it "renders the admin index" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #releases" do
    let(:release_body) do
      <<~BODY
        ## Version 1.2.0

        **New feature:** Fixed the widget

        - Bug fix Y
        - Bug fix Z

        ## Docker Images

        Ignored tail content
        [Read the full changelog here](https://example.com/changelog)
      BODY
    end

    let(:api_body) do
      JSON.generate([
        {
          "name" => "Version 1.2.0",
          "tag_name" => "v1.2.0",
          "published_at" => 2.days.ago.iso8601,
          "body" => release_body,
          "html_url" => "https://github.com/chobbledotcom/play-test/releases/v1.2.0",
          "author" => {"login" => "developer1"}
        },
        {
          "name" => "Version 1.1.0",
          "tag_name" => "v1.1.0",
          "published_at" => 1.week.ago.iso8601,
          "body" => nil,
          "html_url" => "https://github.com/chobbledotcom/play-test/releases/v1.1.0",
          "author" => {"login" => "github-actions[bot]"}
        }
      ])
    end

    def http_response(code, body)
      response = Net::HTTPResponse.new("1.1", code, "OK")
      response.instance_variable_set(:@read, true)
      response.instance_variable_set(:@body, body)
      response
    end

    def stub_github_response(code: "200", body: api_body)
      allow(controller).to receive(:make_github_api_request)
        .and_return(http_response(code, body))
    end

    it "parses releases returned by the GitHub API" do
      stub_github_response
      get :releases

      releases = assigns(:releases)
      expect(releases.first[:name]).to eq("Version 1.2.0")
      expect(releases.last[:name]).to eq("Version 1.1.0")
      # format_release details
      first = releases.first
      expect(first[:author]).to eq("developer1")
      expect(first[:is_bot]).to be(false)
      # process_release_body truncates the Docker Images tail
      expect(first[:body]).not_to include("Ignored tail content")
      expect(first[:body]).not_to include("Read the full changelog here")
      # convert_markdown_to_html output
      expect(first[:body]).to include("<strong>New feature:</strong>")
      expect(first[:body]).to include("<li>Bug fix Y</li>")
      expect(first[:body]).to include("<ul>")
      # bot release has no rendered author marker
      expect(releases.last[:is_bot]).to be(true)
      expect(releases.last[:body]).to be_nil
    end

    it "returns an empty list when the API responds with an error status" do
      stub_github_response(code: "500", body: "oops")
      get :releases
      expect(assigns(:releases)).to eq([])
    end

    it "renders the error flash when the GitHub request raises" do
      allow(controller).to receive(:make_github_api_request)
        .and_raise(StandardError, "network down")
      get :releases
      expect(assigns(:releases)).to eq([])
      expect(flash.now[:error]).to eq(I18n.t("admin.releases.fetch_error"))
    end
  end

  describe "GET #files" do
    it "renders the files page" do
      get :files
      expect(response).to have_http_status(:success)
    end
  end

  describe "private release helpers" do
    describe "#process_release_body" do
      it "returns nil for a blank body" do
        result = controller.send(:process_release_body, nil)
        expect(result).to be_nil
      end

      it "converts markdown to HTML" do
        body = "**Bold** and - an item"
        result = controller.send(:process_release_body, body)
        expect(result).to include("<strong>Bold</strong>")
      end
    end

    describe "#wrap_paragraphs" do
      it "wraps plain text in paragraphs" do
        result = controller.send(:wrap_paragraphs, "first\n\nsecond")
        expect(result).to eq("<p>first</p>\n<p>second</p>")
      end

      it "leaves content containing a heading untouched" do
        result = controller.send(:wrap_paragraphs, "<h2>Heading</h2>")
        expect(result).to eq("<h2>Heading</h2>")
      end
    end
  end
end
