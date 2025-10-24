# typed: false
# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.describe "Litestream Configuration" do
  describe "configuration file" do
    let(:config_path) { Rails.root.join("config/litestream.yml") }
    let(:config) { YAML.load_file(config_path) }

    it "is valid YAML with required databases" do
      expect(File.exist?(config_path)).to be true

      db_paths = config["dbs"].map { |db| db["path"] }
      expect(db_paths).to include("storage/production.sqlite3")
      expect(db_paths).to include("storage/production_queue.sqlite3")
      expect(db_paths).to include("storage/development.sqlite3")
    end

    it "uses S3 replicas with environment variable placeholders" do
      replica = config["dbs"].first["replicas"].first

      expect(replica["type"]).to eq("s3")
      expect(replica["bucket"]).to eq("${LITESTREAM_S3_BUCKET}")
      expect(replica["access-key-id"]).to eq("${LITESTREAM_ACCESS_KEY_ID}")
      secret_key = "${LITESTREAM_SECRET_ACCESS_KEY}"
      expect(replica["secret-access-key"]).to eq(secret_key)
    end
  end

  describe "typed configuration" do
    it "is registered as Sorbet-typed config in Rails" do
      expect(Rails.configuration).to respond_to(:litestream_config)
      expect(Rails.configuration.litestream_config).to be_a(LitestreamConfig)

      config = Rails.configuration.litestream_config
      expect(config.enabled).to be_in([true, false])
    end
  end

  describe "initializer" do
    it "configures litestream gem from typed config when enabled" do
      content = Rails.root.join("config/initializers/litestream.rb").read

      expect(content).to include("Rails.configuration.litestream_config")
      expect(content).to include("return unless")
      expect(content).to include("replica_bucket")
      expect(content).to include("replica_key_id")
      expect(content).to include("replica_access_key")
    end
  end

  describe "Puma plugin integration" do
    it "loads Litestream plugin except in test environment" do
      content = Rails.root.join("config/puma.rb").read

      expect(content).to include("plugin :litestream")
      expect(content).to include("LITESTREAM_ENABLED")
      expect(content).to include('!= "test"')
    end
  end

  describe "docker entrypoint" do
    it "restores databases from S3 on startup when enabled" do
      content = Rails.root.join("bin/docker-entrypoint").read

      expect(content).to include("LITESTREAM_ENABLED")
      expect(content).to include("litestream restore")
      expect(content).to include("production.sqlite3")
      expect(content).to include("production_queue.sqlite3")
      expect(content).not_to include("litestream replicate")
    end
  end

  describe "environment variables" do
    it "documents all Litestream configuration in .env.example" do
      content = Rails.root.join(".env.example").read

      expect(content).to include("LITESTREAM_ENABLED")
      expect(content).to include("LITESTREAM_S3_BUCKET")
      expect(content).to include("LITESTREAM_ACCESS_KEY_ID")
      expect(content).to include("LITESTREAM_SECRET_ACCESS_KEY")
    end
  end

  describe "database configuration" do
    it "enables WAL mode for Litestream compatibility" do
      content = Rails.root.join("config/database.yml").read

      expect(content).to include("journal_mode: wal")
    end
  end
end
