# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackupService, type: :service do
  let(:service) { described_class.new }
  let(:timestamp) { "2026-09-11" }
  let(:workdir) { Dir.mktmpdir("backup-spec") }
  let(:source_db) { Pathname.new(workdir).join("source/database.sqlite3") }
  let(:queue_db) { Pathname.new(workdir).join("source/queue.sqlite3") }
  let(:storage_root) { Pathname.new(workdir).join("source/storage") }
  let(:archive_dir) { Pathname.new(workdir).join("archives") }
  let(:fake_s3) { FakeS3Resource.new("test-bucket") }

  before do
    allow(Time).to receive(:current).and_return(Time.zone.parse("2026-09-11 10:00:00"))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("S3_BUCKET").and_return("test-bucket")

    create_sqlite_database(source_db, rows: %w[Alpha Beta])
    create_sqlite_database(queue_db, rows: %w[QueueRow])
  end

  after do
    FileUtils.rm_rf(workdir)
  end

  def write_storage_file(relative_path, content)
    path = Pathname.new(workdir).join("source/storage", relative_path)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
    path
  end

  describe "#perform" do
    context "when the destination is local" do
      it "creates an archive containing every database" do
        result = service.perform(
          destination: :local,
          db_paths: [source_db, queue_db],
          storage_root:,
          archive_dir:
        )

        expect(result[:destination]).to eq("local")

        archive = archive_dir.join("backup-#{timestamp}.tar.gz")
        expect(archive).to exist

        extract_dir = Pathname.new(workdir).join("extract")
        FileUtils.mkdir_p(extract_dir)
        system("tar", "-xzf", archive.to_s, "-C", extract_dir.to_s, exception: true)

        expect(extract_dir.join("db/database.sqlite3")).to exist
        expect(extract_dir.join("db/queue.sqlite3")).to exist
        expect(widget_names(extract_dir.join("db/database.sqlite3"))).to eq(%w[Alpha Beta])
        expect(widget_names(extract_dir.join("db/queue.sqlite3"))).to eq(%w[QueueRow])
      end

      it "includes every Active Storage file keyed by its blob key" do
        write_storage_file("ab/c1/abc123", "card content")
        write_storage_file("xy/z7/xyz789", "body content")

        service.perform(
          destination: :local,
          db_paths: [source_db],
          storage_root:,
          archive_dir:
        )

        extract_dir = Pathname.new(workdir).join("extract")
        FileUtils.mkdir_p(extract_dir)
        system("tar", "-xzf", archive_dir.join("backup-#{timestamp}.tar.gz").to_s, "-C", extract_dir.to_s, exception: true)

        expect(extract_dir.join("active_storage/abc123").read).to eq("card content")
        expect(extract_dir.join("active_storage/xyz789").read).to eq("body content")
      end

      it "excludes database files, hidden files and the backup folder" do
        write_storage_file("ab/c1/abc123", "card content")
        write_storage_file("ignored.sqlite3", "not a backup target")
        write_storage_file("ignored.sqlite3-wal", "wal")
        write_storage_file(".keep", "hidden")
        nested_archive = storage_root.join("backups")
        FileUtils.mkdir_p(nested_archive)
        File.write(nested_archive.join("backup-2026-01-01.tar.gz"), "old")

        service.perform(
          destination: :local,
          db_paths: [source_db],
          storage_root:,
          archive_dir: nested_archive
        )

        extract_dir = Pathname.new(workdir).join("extract")
        FileUtils.mkdir_p(extract_dir)
        system("tar", "-xzf", nested_archive.join("backup-#{timestamp}.tar.gz").to_s, "-C", extract_dir.to_s, exception: true)

        storage_files = extract_dir.join("active_storage").children.map(&:basename).map(&:to_s)
        expect(storage_files).to contain_exactly("abc123")
      end
      it "cleans up its temporary staging directory" do
        service.perform(
          destination: :local,
          db_paths: [source_db],
          storage_root:,
          archive_dir:
        )

        expect(Pathname.glob(Rails.root.join("tmp/backups/run-*"))).to be_empty
      end
    end

    context "when the destination is s3" do
      it "uploads the archive to S3 under the full_backups prefix" do
        write_storage_file("ab/c1/abc123", "card content")

        result = service.perform(
          destination: :s3,
          db_paths: [source_db],
          storage_root:,
          archive_dir:,
          s3_resource: fake_s3
        )

        key = "full_backups/backup-#{timestamp}.tar.gz"
        expect(fake_s3.store).to have_key(key)
        expect(result[:location]).to eq(key)
        expect(archive_dir.join("backup-#{timestamp}.tar.gz")).not_to exist
      end
    end

    context "when the destination is both" do
      it "writes to local and uploads to S3" do
        write_storage_file("ab/c1/abc123", "card content")

        service.perform(
          destination: :both,
          db_paths: [source_db],
          storage_root:,
          archive_dir:,
          s3_resource: fake_s3
        )

        expect(archive_dir.join("backup-#{timestamp}.tar.gz")).to exist
        expect(fake_s3.store).to have_key("full_backups/backup-#{timestamp}.tar.gz")
      end
    end

    context "when Active Storage is backed by S3" do
      it "snapshots every object except previous backups" do
        stub_active_storage_as_s3
        fake_s3.object("blob-key-1").put(body: "card content")
        fake_s3.object("blob-key-2").put(body: "body content")
        fake_s3.object("full_backups/backup-2026-01-01.tar.gz").put(body: "backup")
        fake_s3.object("db_backups/database-2026-01-01.tar.gz").put(body: "legacy")

        service.perform(
          destination: :local,
          db_paths: [source_db],
          storage_root: nil,
          archive_dir:,
          s3_resource: fake_s3
        )

        extract_dir = Pathname.new(workdir).join("extract")
        FileUtils.mkdir_p(extract_dir)
        system("tar", "-xzf", archive_dir.join("backup-#{timestamp}.tar.gz").to_s, "-C", extract_dir.to_s, exception: true)

        storage_files = extract_dir.join("active_storage").children.map(&:basename).map(&:to_s)
        expect(storage_files).to contain_exactly("blob-key-1", "blob-key-2")
      end

      it "preserves the full key of nested S3 objects in the archive" do
        stub_active_storage_as_s3
        fake_s3.object("a/custom/key-1").put(body: "nested content")

        service.perform(
          destination: :local,
          db_paths: [source_db],
          storage_root: nil,
          archive_dir:,
          s3_resource: fake_s3
        )

        extract_dir = Pathname.new(workdir).join("extract")
        FileUtils.mkdir_p(extract_dir)
        archive = archive_dir.join("backup-#{timestamp}.tar.gz")
        system("tar", "-xzf", archive.to_s, "-C", extract_dir.to_s, exception: true)

        nested = extract_dir.join("active_storage/a/custom/key-1")
        expect(nested.read).to eq("nested content")
      end
    end

    context "when cleaning up old archives" do
      it "deletes local archives older than the retention period" do
        old_archive = archive_dir.join("backup-2020-01-01.tar.gz")
        FileUtils.mkdir_p(archive_dir)
        FileUtils.touch(old_archive, mtime: Time.zone.parse("2020-01-01 00:00:00").to_time)

        service.perform(
          destination: :local,
          db_paths: [source_db],
          storage_root:,
          archive_dir:
        )

        expect(old_archive).not_to exist
      end

      it "keeps local archives inside the retention period" do
        recent_archive = archive_dir.join("backup-2026-09-01.tar.gz")
        FileUtils.mkdir_p(archive_dir)
        FileUtils.touch(recent_archive, mtime: Time.zone.parse("2026-09-01 00:00:00").to_time)

        service.perform(
          destination: :local,
          db_paths: [source_db],
          storage_root:,
          archive_dir:
        )

        expect(recent_archive).to exist
      end

      it "deletes S3 archives older than the retention period" do
        fake_s3.object("full_backups/backup-2020-01-01.tar.gz")
          .with_last_modified(Time.zone.parse("2020-01-01 00:00:00"))
          .put(body: "old")

        service.perform(
          destination: :s3,
          db_paths: [source_db],
          storage_root:,
          archive_dir:,
          s3_resource: fake_s3
        )

        expect(fake_s3.store).not_to have_key("full_backups/backup-2020-01-01.tar.gz")
      end

      it "keeps S3 archives inside the retention period" do
        fake_s3.object("full_backups/backup-2026-09-01.tar.gz")
          .with_last_modified(Time.zone.parse("2026-09-01 00:00:00"))
          .put(body: "recent")

        service.perform(
          destination: :s3,
          db_paths: [source_db],
          storage_root:,
          archive_dir:,
          s3_resource: fake_s3
        )

        expect(fake_s3.store).to have_key("full_backups/backup-2026-09-01.tar.gz")
      end
    end

    context "with invalid configuration" do
      it "raises for an unknown destination" do
        expect {
          service.perform(destination: :nowhere, db_paths: [source_db], storage_root:)
        }.to raise_error(ArgumentError, "Unknown destination: nowhere. Use local, s3 or both.")
      end

      it "raises when there are no databases and no local storage root" do
        stub_active_storage_as_s3

        expect {
          service.perform(destination: :local, db_paths: [], storage_root: nil)
        }.to raise_error("No databases to back up")
      end
    end
  end
end
