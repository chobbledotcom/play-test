# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicContainer::EnvBuilder do
  subject(:env) { described_class.build(answers).to_h }

  let(:answers) do
    MagicContainer::Answers.new(
      access_key: "bunny-key",
      app_name: "play-test",
      archive_path: Pathname.new("/tmp/backup-2026-01-01.tar.gz"),
      base_url: base_url,
      display_app_name: display_app_name,
      image_ref: "chobble/play-test",
      image_tag: "latest",
      litestream_s3: MagicContainer::S3Details.new(
        access_key_id: "ls-key",
        bucket: "ls-bucket",
        endpoint: "https://ls.example.com",
        region: "ldn",
        secret_access_key: "ls-secret"
      ),
      rails_master_key: master_key,
      region: "LDN",
      registry_id: "7",
      runtime_type: "shared",
      secret_key_base: "generated-secret",
      sentry_dsn: sentry_dsn,
      storage_s3: MagicContainer::S3Details.new(
        access_key_id: "as-key",
        bucket: "as-bucket",
        endpoint: "https://as.example.com",
        region: "ldn",
        secret_access_key: "as-secret"
      )
    )
  end

  let(:base_url) { "" }
  let(:display_app_name) { "Play-Test" }
  let(:master_key) { "" }
  let(:sentry_dsn) { "" }

  it "configures Active Storage for the S3 bucket" do
    expect(env).to include(
      "S3_ACCESS_KEY_ID" => "as-key",
      "S3_BUCKET" => "as-bucket",
      "S3_ENDPOINT" => "https://as.example.com",
      "S3_REGION" => "ldn",
      "S3_SECRET_ACCESS_KEY" => "as-secret",
      "USE_S3_STORAGE" => "true"
    )
  end

  it "configures litestream so the container restores on first boot" do
    expect(env).to include(
      "LITESTREAM_ACCESS_KEY_ID" => "ls-key",
      "LITESTREAM_ENABLED" => "true",
      "LITESTREAM_S3_BUCKET" => "ls-bucket",
      "LITESTREAM_S3_ENDPOINT" => "https://ls.example.com",
      "LITESTREAM_S3_REGION" => "ldn",
      "LITESTREAM_SECRET_ACCESS_KEY" => "ls-secret"
    )
  end

  it "includes the rails essentials" do
    expect(env).to include(
      "APP_NAME" => "Play-Test",
      "SECRET_KEY_BASE" => "generated-secret"
    )
  end

  it "omits optional variables that were left blank" do
    expect(env.keys).not_to include("BASE_URL", "RAILS_MASTER_KEY", "SENTRY_DSN")
  end

  context "with optional values" do
    let(:base_url) { "https://example.com" }
    let(:master_key) { "master-key" }
    let(:sentry_dsn) { "https://sentry.example.com/1" }

    it "includes every optional variable" do
      expect(env).to include(
        "BASE_URL" => "https://example.com",
        "RAILS_MASTER_KEY" => "master-key",
        "SENTRY_DSN" => "https://sentry.example.com/1"
      )
    end
  end
end
