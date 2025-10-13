# typed: false
# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_admin

  def index
    @show_backups = Rails.configuration.use_s3_storage
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

  def files
    @blobs = ActiveStorage::Blob
      .where.not(id: ActiveStorage::VariantRecord.select(:blob_id))
      .includes(attachments: :record)
      .order(created_at: :desc)
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
      JSON.parse(response.body).map { |release| format_release(release) }
    else
      log_msg = "GitHub API returned #{response.code}: #{response.body}"
      Rails.logger.error log_msg
      []
    end
  end

  def format_release(release)
    {
      name: release["name"],
      tag_name: release["tag_name"],
      published_at: Time.zone.parse(release["published_at"]),
      body: process_release_body(release["body"]),
      html_url: release["html_url"],
      author: release["author"]["login"],
      is_bot: release["author"]["login"].include?("[bot]")
    }
  end

  def process_release_body(body)
    return nil if body.blank?

    # Find the position of "## Docker Images" and truncate
    docker_index = body.index("## Docker Images")
    processed_body = docker_index ? body[0...docker_index].strip : body

    # Remove [Read the full changelog here] links
    changelog_pattern = /\[Read the full changelog here\]\([^)]+\)/
    processed_body = processed_body.gsub(changelog_pattern, "")
    processed_body = processed_body.strip

    convert_markdown_to_html(processed_body)
  end

  def convert_markdown_to_html(text)
    # Remove headers (they duplicate version info)
    html = text.gsub(/^### .+$/, "")
    html = html.gsub(/^## .+$/, "")
    html = html.gsub(/^# .+$/, "")

    # Clean up extra newlines from removed headers
    html = html.gsub(/\n{3,}/, "\n\n").strip

    # Convert bold and bullet points
    html = html.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
    html = convert_bullet_points(html)

    # Convert line breaks to paragraphs
    wrap_paragraphs(html)
  end

  def convert_bullet_points(text)
    html = text.gsub(/^- (.+)$/, '<li>\1</li>')
    html.gsub(/(<li>.*<\/li>)/m) { |match| "<ul>#{match}</ul>" }
  end

  def wrap_paragraphs(text)
    text.split("\n\n").map do |paragraph|
      next if paragraph.strip.empty?
      if paragraph.include?("<h") || paragraph.include?("<ul>")
        paragraph
      else
        "<p>#{paragraph}</p>"
      end
    end.compact.join("\n")
  end
end
