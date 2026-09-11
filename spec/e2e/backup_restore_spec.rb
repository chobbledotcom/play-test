# typed: false
# frozen_string_literal: true

require "rails_helper"

# End-to-end tests for the backup and restore system. They exercise the full
# round trip against real SQLite database files, real tar archives and real
# Active Storage disk services, so they cover the actual backup -> restore
# flow rather than mocked internals.
RSpec.describe "Backup and restore end to end", type: :service do
  let(:workdir) { Dir.mktmpdir("backup-e2e") }
  let(:source_db) { Pathname.new(workdir).join("source/database.sqlite3") }
  let(:source_queue_db) { Pathname.new(workdir).join("source/production_queue.sqlite3") }
  let(:storage_root) { Pathname.new(workdir).join("source/storage") }
  let(:archive_dir) { Pathname.new(workdir).join("source/backups") }
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
    create_sqlite_database(source_queue_db, rows: %w[QueueRow])
    write_storage_file("ab/c1/abc123", "card content")
    write_storage_file("xy/z7/xyz789", "body content")
  end

  after do
    FileUtils.rm_rf(workdir)
  end

  def write_storage_file(relative_path, content)
    path = storage_root.join(relative_path)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
    path
  end

  describe "backing up" do
    it "backs up every database and Active Storage file into a single archive" do
      BackupService.new.perform(
        destination: :local,
        db_paths: [source_db, source_queue_db],
        storage_root:,
        archive_dir:
      )

      archive = archive_dir.join("backup-2026-09-11.tar.gz")
      expect(archive).to exist

      extract_dir = Pathname.new(workdir).join("extract")
      FileUtils.mkdir_p(extract_dir)
      system("tar", "-xzf", archive.to_s, "-C", extract_dir.to_s, exception: true)

      expect(widget_names(extract_dir.join("db/database.sqlite3"))).to eq(%w[Alpha Beta])
      expect(widget_names(extract_dir.join("db/production_queue.sqlite3"))).to eq(%w[QueueRow])
      expect(extract_dir.join("active_storage/abc123").read).to eq("card content")
      expect(extract_dir.join("active_storage/xyz789").read).to eq("body content")
    end
  end

  describe "restoring" do
    context "to local storage" do
      let(:target_db) { Pathname.new(workdir).join("target/database.sqlite3") }
      let(:target_queue_db) { Pathname.new(workdir).join("target/production_queue.sqlite3") }
      let(:target_root) { Pathname.new(workdir).join("target/storage") }
      let(:target_service) { ActiveStorage::Service::DiskService.new(root: target_root) }

      before do
        BackupService.new.perform(
          destination: :local,
          db_paths: [source_db, source_queue_db],
          storage_root:,
          archive_dir:
        )
      end

      it "round-trips databases and files back into a fresh local setup" do
        service = RestoreService.new
        result = service.perform(
          date: "2026-09-11",
          storage_target: :local,
          db_paths: [target_db, target_queue_db],
          archive_dir:,
          storage_service: target_service
        )

        expect(result[:restored_databases]).to contain_exactly("database.sqlite3", "production_queue.sqlite3")

        expect(widget_names(target_db)).to eq(%w[Alpha Beta])
        expect(widget_names(target_queue_db)).to eq(%w[QueueRow])

        expect(target_root.join("ab/c1/abc123").read).to eq("card content")
        expect(target_root.join("xy/z7/xyz789").read).to eq("body content")

        # Files land where the disk service expects them
        expect(target_service.exist?("abc123")).to be true
        expect(target_service.exist?("xyz789")).to be true
        expect(target_service.exist?("missing")).to be false

        # Blobs that were on S3 now point at the local service
        expect(blob_service_names(target_db)).to eq(%w[local local])
      end

      it "writes the restored blobs to the path the app would serve them from" do
        RestoreService.new.perform(
          date: "2026-09-11",
          storage_target: :local,
          db_paths: [target_db, target_queue_db],
          archive_dir:,
          storage_service: target_service
        )

        path = target_root.join("ab/c1/abc123")
        expect(path).to exist
        expect(path.read).to eq("card content")
      end
    end

    context "to object storage" do
      let(:target_db) { Pathname.new(workdir).join("target/database.sqlite3") }

      before do
        BackupService.new.perform(
          destination: :s3,
          db_paths: [source_db],
          storage_root:,
          archive_dir: Pathname.new(workdir).join("empty"),
          s3_resource: fake_s3
        )
      end

      it "round-trips through S3, uploading files with their blob keys" do
        uploaded = {}
        s3_storage = double("s3 storage", name: "s3_host")
        allow(s3_storage).to receive(:upload) { |key, io| uploaded[key] = io.read }

        result = RestoreService.new.perform(
          date: "2026-09-11",
          storage_target: :s3,
          db_paths: [target_db],
          archive_dir: Pathname.new(workdir).join("empty"),
          storage_service: s3_storage,
          s3_resource: fake_s3
        )

        expect(result[:location]).to eq("s3://test-bucket/full_backups/backup-2026-09-11.tar.gz")
        expect(widget_names(target_db)).to eq(%w[Alpha Beta])
        expect(uploaded).to eq({
          "abc123" => "card content",
          "xyz789" => "body content"
        })
        expect(blob_service_names(target_db)).to eq(%w[s3_host s3_host])
      end
    end
  end
end
