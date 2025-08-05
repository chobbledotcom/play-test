# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_admin

  def index
    @show_backups = ENV["USE_S3_STORAGE"] == "true"
  end

  def releases
    @releases = Rails.cache.fetch("github_releases", expires_in: 1.hour) do
      fetch_github_releases
    end
  rescue => e
    Rails.logger.error "Failed to fetch GitHub releases: #{e.message}"
    @releases = []
    flash.now[:error] = t("admin.releases.fetch_error")
  end

  private

  def fetch_github_releases
    response = make_github_api_request
    parse_github_response(response)
  end

  def make_github_api_request
    require "net/http"

    uri = URI("https://api.github.com/repos/chobbledotcom/play-test/releases")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github.v3+json"
    request["User-Agent"] = "PlayTest-Admin"

    http.request(request)
  end

  def parse_github_response(response)
    require "json"

    if response.code == "200"
      JSON.parse(response.body).map do |release|
        {
          name: release["name"],
          tag_name: release["tag_name"],
          published_at: Time.zone.parse(release["published_at"]),
          body: release["body"],
          html_url: release["html_url"],
          author: release["author"]["login"]
        }
      end
    else
      log_msg = "GitHub API returned #{response.code}: #{response.body}"
      Rails.logger.error log_msg
      []
    end
  end
end
