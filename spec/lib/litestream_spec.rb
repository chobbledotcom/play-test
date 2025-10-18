# typed: false
# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.describe "Litestream Configuration" do
  describe "configuration file" do
    let(:config_path) { Rails.root.join("config/litestream.yml") }
    let(:config) { YAML.load_file(config_path) }

    it "exists" do
      expect(File.exist?(config_path)).to be true
    end

    it "is valid YAML" do
      expect { config }.not_to raise_error
    end

    it "configures production database replication" do
      production_db = config["dbs"].find do |db|
        db["path"] == "storage/production.sqlite3"
      end

      expect(production_db).to be_present
      expect(production_db["replicas"]).to be_present
      expect(production_db["replicas"].first["type"]).to eq("s3")
    end

    it "configures production queue database replication" do
      queue_db = config["dbs"].find do |db|
        db["path"] == "storage/production_queue.sqlite3"
      end

      expect(queue_db).to be_present
      expect(queue_db["replicas"]).to be_present
      expect(queue_db["replicas"].first["type"]).to eq("s3")
    end

    it "uses environment variables for S3 credentials" do
      production_db = config["dbs"].first
      replica = production_db["replicas"].first

      expect(replica["bucket"]).to eq("${LITESTREAM_S3_BUCKET}")
      expect(replica["endpoint"]).to eq("${LITESTREAM_S3_ENDPOINT}")
      expect(replica["region"]).to eq("${LITESTREAM_S3_REGION}")
      expect(replica["access-key-id"]).to eq("${LITESTREAM_ACCESS_KEY_ID}")
      secret_key = replica["secret-access-key"]
      expect(secret_key).to eq("${LITESTREAM_SECRET_ACCESS_KEY}")
    end

    it "sets reasonable retention and sync intervals" do
      production_db = config["dbs"].first
      replica = production_db["replicas"].first

      expect(replica["sync-interval"]).to be_present
      expect(replica["retention"]).to be_present
      expect(replica["snapshot-interval"]).to be_present
    end
  end

  describe "initializer" do
    let(:initializer_path) do
      Rails.root.join("config/initializers/litestream.rb")
    end

    it "exists" do
      expect(File.exist?(initializer_path)).to be true
    end

    it "configures S3 credentials from environment variables" do
      content = File.read(initializer_path)

      expect(content).to include("LITESTREAM_S3_BUCKET")
      expect(content).to include("LITESTREAM_ACCESS_KEY_ID")
      expect(content).to include("LITESTREAM_SECRET_ACCESS_KEY")
      expect(content).to include("replica_bucket")
      expect(content).to include("replica_key_id")
      expect(content).to include("replica_access_key")
    end

    it "configures optional S3 endpoint and region" do
      content = File.read(initializer_path)

      expect(content).to include("LITESTREAM_S3_ENDPOINT")
      expect(content).to include("LITESTREAM_S3_REGION")
      expect(content).to include("replica_endpoint")
      expect(content).to include("replica_region")
    end
  end

  describe "Puma plugin integration" do
    let(:puma_config_path) { Rails.root.join("config/puma.rb") }
    let(:puma_config_content) { File.read(puma_config_path) }

    it "loads Litestream plugin in production when enabled" do
      expect(puma_config_content).to include("plugin :litestream")
    end

    it "conditionally enables based on LITESTREAM_ENABLED" do
      expect(puma_config_content).to include("LITESTREAM_ENABLED")
    end

    it "only runs in production environment" do
      expect(puma_config_content).to include("production")
    end
  end

  describe "docker entrypoint" do
    let(:entrypoint_path) { Rails.root.join("bin/docker-entrypoint") }
    let(:entrypoint_content) { File.read(entrypoint_path) }

    it "restores databases from S3 when LITESTREAM_ENABLED is true" do
      expect(entrypoint_content).to include("LITESTREAM_ENABLED")
      expect(entrypoint_content).to include("litestream restore")
    end

    it "checks for both production and queue databases" do
      expect(entrypoint_content).to include("production.sqlite3")
      expect(entrypoint_content).to include("production_queue.sqlite3")
    end

    it "handles missing backups gracefully" do
      expect(entrypoint_content).to include("No backup found")
    end

    it "does not start litestream manually (handled by Puma plugin)" do
      expect(entrypoint_content).not_to include("litestream replicate")
    end
  end

  describe "environment variables documentation" do
    let(:env_example_path) { Rails.root.join(".env.example") }
    let(:env_example_content) { File.read(env_example_path) }

    it "documents LITESTREAM_ENABLED" do
      expect(env_example_content).to include("LITESTREAM_ENABLED")
    end

    it "documents S3 configuration for Litestream" do
      expect(env_example_content).to include("LITESTREAM_S3_BUCKET")
      expect(env_example_content).to include("LITESTREAM_S3_ENDPOINT")
      expect(env_example_content).to include("LITESTREAM_S3_REGION")
      expect(env_example_content).to include("LITESTREAM_ACCESS_KEY_ID")
      expect(env_example_content).to include("LITESTREAM_SECRET_ACCESS_KEY")
    end

    it "includes helpful comments" do
      expect(env_example_content).to include("Litestream Configuration")
      expect(env_example_content).to include("SQLite Replication")
    end
  end

  describe "litestream binary" do
    it "is available via bundle exec" do
      output = `bundle exec litestream version 2>&1`
      expect($?.success?).to be true
      expect(output).to match(/v\d+\.\d+\.\d+/)
    end
  end
end
