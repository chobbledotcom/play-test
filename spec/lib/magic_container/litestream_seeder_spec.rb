# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicContainer::LitestreamSeeder do
  subject(:seeder) do
    described_class.new(
      db_path: db_path,
      replica_path: "production.sqlite3",
      s3: s3_details,
      runner: runner
    )
  end

  let(:db_path) { Pathname.new(workdir).join("production.sqlite3") }
  let(:workdir) { Dir.mktmpdir("seeder-spec") }
  let(:s3_details) do
    MagicContainer::S3Details.new(
      access_key_id: "ls-key",
      bucket: "ls-bucket",
      endpoint: "https://ls.example.com",
      region: "ldn",
      secret_access_key: "ls-secret"
    )
  end
  let(:commands) { [] }
  let(:snapshot_outputs) { [] }
  let(:final_snapshot_output) { "production.sqlite3    2026-01-01T10:00:00Z  123 generations" }
  let(:runner) do
    lambda { |args|
      commands << args
      if args.include?("snapshots")
        [snapshot_outputs.shift || final_snapshot_output, true]
      else
        ["replicating", true]
      end
    }
  end

  before do
    File.write(db_path, "sqlite")
    allow(seeder).to receive(:sleep)
  end

  after { FileUtils.rm_rf(workdir) }

  it "replicates once with a generated config and verifies the snapshot" do
    seeder.call

    replicate = commands.first
    expect(replicate).to include("replicate", "sleep #{described_class::SEED_SECONDS}")
    config_flag = replicate[replicate.index("-config") + 1]
    expect(File).to exist(config_flag)

    verify = commands.last
    expect(verify).to include("snapshots", db_path.to_s)
  end

  it "mirrors the container replica layout in the config" do
    seeder.call

    replicate = commands.first
    config_path = replicate[replicate.index("-config") + 1]
    config = YAML.load_file(config_path)
    replica = config.fetch("dbs").first.fetch("replicas").first

    expect(config.fetch("dbs").first.fetch("path")).to eq(db_path.to_s)
    expect(replica).to include(
      "access-key-id" => "ls-key",
      "bucket" => "ls-bucket",
      "endpoint" => "https://ls.example.com",
      "path" => "production.sqlite3",
      "region" => "ldn",
      "secret-access-key" => "ls-secret",
      "type" => "s3"
    )
  end

  it "retries until a snapshot appears in the replica" do
    snapshot_outputs << "" << ""

    seeder.call

    replicate_runs = commands.count { it.include?("replicate") }
    expect(replicate_runs).to eq(3)
  end

  it "raises when no snapshot appears after every attempt" do
    snapshot_outputs.concat([""] * 6)

    expect { seeder.call }.to raise_error(/No Litestream snapshot appeared in ls-bucket/)
  end
end
