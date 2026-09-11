# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe RestoreService, type: :service do
  let(:service) { described_class.new }
  let(:timestamp) { "2026-09-11" }
  let(:workdir) { Dir.mktmpdir("restore-spec") }
  let(:archive_dir) { Pathname.new(workdir).join("archives") }
  let(:source_db) { Pathname.new(workdir).join("source/database.sqlite3") }
  let(:storage_root) { Pathname.new(workdir).join("source/storage") }
  let(:fake_s3) { FakeS3Resource.new("test-bucket") }

  before do
    allow(Time).to receive(:current).and_return(Time.zone.parse("2026-09-11 10:00:00"))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("S3_BUCKET").and_return("test-bucket")

    create_sqlite_database(
      source_db,
      rows: %w[Alpha Beta],
      blobs: [
        {key: "abc123", filename: "card.png", service_name: "s3_host"},
        {key: "xyz789", filename: "body.png", service_name: "s3_host"}
      ]
    )
    write_storage_file("ab/c1/abc123", "card content")
    write_storage_file("xy/z7/xyz789", "body content")
  end

  after do
    FileUtils.rm_rf(workdir)
    remove_process_snapshots
  end

  def write_storage_file(relative_path, content)
    path = storage_root.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
    path
  end

  def create_archive(destination: :local, s3_resource: nil)
    BackupService.new.perform(
      destination:,
      db_paths: [source_db],
      storage_root:,
      archive_dir:,
      s3_resource:
    )
  end

  describe "#perform" do
    it "rejects an invalid date" do
      expect {
        service.perform(date: "not-a-date", archive_dir:)
      }.to raise_error(ArgumentError, "Invalid backup date: not-a-date. Expected YYYY-MM-DD.")
    end

    context "when restoring from a local archive" do
      let(:target_db) { Pathname.new(workdir).join("target/database.sqlite3") }
      let(:target_root) { Pathname.new(workdir).join("target/storage") }

      before do
        create_archive(destination: :local)
        create_sqlite_database(target_db, rows: %w[Existing])
      end

      it "restores the database and every Active Storage file to local disk" do
        result = service.perform(
          date: timestamp,
          storage_target: :local,
          db_paths: [target_db],
          archive_dir:,
          storage_service: ActiveStorage::Service::DiskService.new(root: target_root)
        )

        expect(result[:restored_databases]).to eq(["database.sqlite3"])
        expect(widget_names(target_db)).to eq(%w[Alpha Beta])
        expect(target_root.join("ab/c1/abc123").read).to eq("card content")
        expect(target_root.join("xy/z7/xyz789").read).to eq("body content")
      end

      it "points restored blobs at the local service when migrating" do
        service.perform(
          date: timestamp,
          storage_target: :local,
          db_paths: [target_db],
          archive_dir:,
          storage_service: ActiveStorage::Service::DiskService.new(root: target_root)
        )

        names = blob_service_names(target_db)
        expect(names).to eq(%w[local local])
      end

      it "points restored blobs at the active service for the current target" do
        service.perform(
          date: timestamp,
          storage_target: :current,
          db_paths: [target_db],
          archive_dir:,
          storage_service: ActiveStorage::Service::DiskService.new(root: target_root)
        )

        active_name = ActiveStorage::Blob.service.name.to_s
        expect(active_name).to eq("test")
        expect(blob_service_names(target_db)).to eq([active_name, active_name])
      end

      it "removes stale WAL sidecars beside the restored database" do
        wal = Pathname.new("#{target_db}-wal")
        shm = Pathname.new("#{target_db}-shm")
        File.write(wal, "stale")
        File.write(shm, "stale")

        service.perform(
          date: timestamp,
          storage_target: :local,
          db_paths: [target_db],
          archive_dir:,
          storage_service: ActiveStorage::Service::DiskService.new(root: target_root)
        )

        expect(wal).not_to exist
        expect(shm).not_to exist
      end

      it "keeps a safety snapshot of the current database before overwriting" do
        result = service.perform(
          date: timestamp,
          storage_target: :local,
          db_paths: [target_db],
          archive_dir:,
          storage_service: ActiveStorage::Service::DiskService.new(root: target_root)
        )

        snapshots = Pathname(result[:snapshots_dir]).glob("database.sqlite3.*.pre-restore")
        expect(snapshots.size).to eq(1)
        expect(widget_names(snapshots.first)).to eq(%w[Existing])
      end

      it "raises when the archive contains a database with no matching path" do
        expect {
          service.perform(
            date: timestamp,
            storage_target: :local,
            db_paths: [Pathname.new(workdir).join("elsewhere/other.sqlite3")],
            archive_dir:,
            storage_service: ActiveStorage::Service::DiskService.new(root: target_root)
          )
        }.to raise_error(/database\.sqlite3, which has no matching database/)
      end

      it "rejects db_paths that share a database name" do
        extra = Pathname.new(workdir).join("target-copy/database.sqlite3")

        expect {
          service.perform(
            date: timestamp,
            storage_target: :local,
            db_paths: [target_db, extra],
            archive_dir:,
            storage_service: ActiveStorage::Service::DiskService.new(root: target_root)
          )
        }.to raise_error(ArgumentError, "Duplicate database names: database.sqlite3")
      end

      it "raises when the backup is nowhere to be found" do
        empty_dir = Pathname.new(workdir).join("empty")

        expect {
          service.perform(
            date: "2099-01-01",
            storage_target: :local,
            db_paths: [target_db],
            archive_dir: empty_dir,
            storage_service: ActiveStorage::Service::DiskService.new(root: target_root),
            s3_resource: fake_s3
          )
        }.to raise_error(/not found/)
      end
    end

    context "when restoring from an S3 archive to object storage" do
      let(:target_db) { Pathname.new(workdir).join("target/database.sqlite3") }

      before do
        create_archive(destination: :s3, s3_resource: fake_s3)
        create_sqlite_database(target_db, rows: %w[Existing])
      end

      it "downloads the archive, restores the database and uploads files to S3" do
        uploaded = {}
        s3_storage = double("s3 storage", name: "s3_host")
        allow(s3_storage).to receive(:upload) { |key, io| uploaded[key] = io.read }

        result = service.perform(
          date: timestamp,
          storage_target: :s3,
          db_paths: [target_db],
          archive_dir:,
          storage_service: s3_storage,
          s3_resource: fake_s3
        )

        expect(result[:location]).to eq("s3://test-bucket/full_backups/backup-#{timestamp}.tar.gz")
        expect(widget_names(target_db)).to eq(%w[Alpha Beta])
        expect(uploaded).to eq({
          "abc123" => "card content",
          "xyz789" => "body content"
        })
        expect(blob_service_names(target_db)).to eq(%w[s3_host s3_host])
      end

      it "uploads nested blob keys with their full path" do
        stub_active_storage_as_s3
        fake_s3.object("nested/dir/blob-1").put(body: "nested content")
        BackupService.new.perform(
          destination: :s3,
          db_paths: [source_db],
          storage_root: nil,
          archive_dir:,
          s3_resource: fake_s3
        )

        uploaded = {}
        s3_storage = double("s3 storage", name: "s3_host")
        allow(s3_storage).to receive(:upload) { |key, io| uploaded[key] = io.read }

        service.perform(
          date: timestamp,
          storage_target: :s3,
          db_paths: [target_db],
          archive_dir:,
          storage_service: s3_storage,
          s3_resource: fake_s3
        )

        expect(uploaded).to eq("nested/dir/blob-1" => "nested content")
        expect(widget_names(target_db)).to eq(%w[Alpha Beta])
      end
    end

    context "with an unknown storage target" do
      it "raises when no storage service is provided" do
        create_archive(destination: :local)
        target_db = Pathname.new(workdir).join("target/database.sqlite3")
        create_sqlite_database(target_db)

        expect {
          service.perform(
            date: timestamp,
            storage_target: :bogus,
            db_paths: [target_db],
            archive_dir:
          )
        }.to raise_error(ArgumentError, /Unknown storage target: bogus/)
      end
    end
  end
end
