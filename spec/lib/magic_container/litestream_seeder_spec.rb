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
  # Litestream v0.3.13 lists a header row plus one row per snapshot. The
  # rows carry the replica name (not the path), generation, index, size and
  # creation time - which is why the old path-matching check never passed.
  let(:listing_with_snapshot) do
    <<~LISTING
      replica  generation                              index  size  created
      s3       00d7b2e5-4d8a-4bd2-a8a5-9c821c1f3a33    0      24576  2026-01-01T10:00:00Z
    LISTING
  end
  let(:listing_without_snapshot) do
    "replica  generation  index  size  created"
  end
  let(:captured) { [] }
  let(:runner) do
    lambda { |args|
      commands << args
      flag = args.index("-config")
      if flag
        path = args.fetch(flag + 1)
        captured << {path: path, config: YAML.load_file(path)}
      end
      if args.include?("snapshots")
        [snapshot_outputs.shift || listing_with_snapshot, true]
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

    verify = commands.last
    expect(verify).to include("snapshots", db_path.to_s)
    expect(captured).to be_present
  end

  it "mirrors the container replica layout in the config" do
    seeder.call

    config = captured.last.fetch(:config)
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

  it "removes the generated config after seeding" do
    seeder.call

    expect(File).not_to exist(captured.last.fetch(:path))
  end

  it "retries until a snapshot appears in the replica" do
    snapshot_outputs << listing_without_snapshot << listing_without_snapshot

    seeder.call

    replicate_runs = commands.count { it.include?("replicate") }
    expect(replicate_runs).to eq(3)
  end

  it "raises when no snapshot appears after every attempt" do
    snapshot_outputs.concat([listing_without_snapshot] * 6)

    expect { seeder.call }
      .to raise_error(/No Litestream snapshot appeared in ls-bucket/)
  end

  describe "#seeded?" do
    it "is true when the listing has a snapshot row" do
      expect(seeder.seeded?).to be true
      expect(commands).to all(include("snapshots"))
    end

    it "is false when the listing is only the header" do
      snapshot_outputs << listing_without_snapshot

      expect(seeder.seeded?).to be false
    end

    it "removes the generated config after checking" do
      seeder.seeded?

      expect(File).not_to exist(captured.last.fetch(:path))
    end
  end
end
