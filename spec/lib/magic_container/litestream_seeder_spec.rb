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
  # A replica another deployment already wrote to: the growth check must
  # still recognise this call's push, where a presence check would have
  # mistaken the existing rows for our seed.
  let(:crowded_listing) do
    <<~LISTING
      replica  generation                              index  size  created
      s3       11111111-1111-1111-1111-111111111111    0      20480  2025-12-01T10:00:00Z
    LISTING
  end
  let(:grown_listing) do
    "#{crowded_listing}s3       22222222-2222-2222-2222-222222222222" \
      "    0      24576  2026-01-01T10:00:00Z\n"
  end
  let(:captured) { [] }
  # Each listing the seeder captures, in order: the baseline before the
  # first push, then one after every push. A run that exhausts the list
  # sees an empty replica.
  let(:snapshot_outputs) { [listing_without_snapshot, listing_with_snapshot] }
  let(:runner) do
    lambda { |args|
      commands << args
      flag = args.index("-config")
      if flag
        path = args.fetch(flag + 1)
        captured << {path: path, config: YAML.load_file(path)}
      end
      if args.include?("snapshots")
        [snapshot_outputs.shift || listing_without_snapshot, true]
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

  it "seeds and verifies the snapshot from a baseline listing" do
    seeder.call

    # The listing captured before the first push is the baseline
    expect(commands.first).to include("snapshots", db_path.to_s)
    expect(commands.count { it.include?("replicate") }).to eq(1)
    expect(commands.last).to include("snapshots", db_path.to_s)
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

  it "removes the generated config after listing" do
    seeder.listing

    expect(File).not_to exist(captured.last.fetch(:path))
  end

  it "removes the generated config after seeding" do
    seeder.call

    expect(File).not_to exist(captured.last.fetch(:path))
  end

  it "succeeds when the push grows a replica that already held rows" do
    snapshot_outputs.replace([crowded_listing, grown_listing])

    seeder.call

    expect(commands.count { it.include?("replicate") }).to eq(1)
  end

  it "retries until the listing grows" do
    snapshot_outputs.replace(
      [listing_without_snapshot, listing_without_snapshot, listing_with_snapshot]
    )

    seeder.call

    expect(commands.count { it.include?("snapshots") }).to eq(3)
    expect(commands.count { it.include?("replicate") }).to eq(2)
  end

  it "raises when no new rows appear after every attempt" do
    attempts = described_class::ATTEMPTS
    # Baseline, one after each push attempt, plus the listing quoted in
    # the raised error
    snapshot_outputs.replace([listing_without_snapshot] * (attempts + 2))

    expect { seeder.call }.to raise_error(/\ANo Litestream snapshot appeared/)
    expect(commands.count { it.include?("replicate") }).to eq(attempts)
  end

  it "includes the command output when a litestream command fails" do
    status = instance_double(Process::Status, success?: false)
    allow(Open3).to receive(:capture3).and_return(["stdout", "boom", status])
    real_runner = described_class.new(
      db_path: db_path,
      replica_path: "production.sqlite3",
      s3: s3_details
    )

    expect { real_runner.call }
      .to raise_error(/\ALitestream command failed: .+\nboom\z/)
  end
end
