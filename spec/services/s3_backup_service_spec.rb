# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe S3BackupService do
  let(:service) { described_class.new }
  let(:s3_service) { double("S3Service") }
  let(:bucket) { double("S3Bucket") }
  let(:timestamp) { "2024-01-15" }
  let(:temp_dir) { Rails.root.join("tmp/backups") }
  let(:backup_filename) { "database-#{timestamp}.sqlite3" }
  let(:compressed_filename) { "database-#{timestamp}.tar.gz" }
  let(:s3_key) { "db_backups/#{compressed_filename}" }

  # Helper method to mock tar compression and create the compressed file
  def mock_tar_compression(service, content_size: 1000)
    allow(service).to receive(:system).with(
      "tar", "-czf", anything,
      "-C", anything, anything,
      exception: true
    ) do |*args|
      # Extract the destination path from the tar command arguments
      dest_path = args[2]
      # Create the compressed file that would be created by tar
      FileUtils.touch(dest_path)
      File.write(dest_path, "compressed content" * content_size)
      true
    end
  end

  before do
    allow(Time).to receive(:current).and_return(Time.zone.parse("2024-01-15 10:00:00"))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("USE_S3_STORAGE").and_return("true")
    allow(ENV).to receive(:[]).with("S3_ENDPOINT").and_return("https://s3.example.com")
    allow(ENV).to receive(:[]).with("S3_ACCESS_KEY_ID").and_return("access_key")
    allow(ENV).to receive(:[]).with("S3_SECRET_ACCESS_KEY").and_return("secret_key")
    allow(ENV).to receive(:[]).with("S3_BUCKET").and_return("test-bucket")
    allow(ActiveStorage::Blob).to receive(:service).and_return(s3_service)
    allow(s3_service).to receive(:send).with(:bucket).and_return(bucket)

    FileUtils.mkdir_p(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#perform" do
    context "when S3 is not enabled" do
      before do
        allow(ENV).to receive(:[]).with("USE_S3_STORAGE").and_return("false")
        # Mock FileUtils to avoid errors in ensure block
        allow(FileUtils).to receive(:rm_f)
      end

      it "raises an error" do
        expect { service.perform }.to raise_error(RuntimeError, "S3 storage is not enabled")
      end
    end

    context "when S3 config is missing" do
      before do
        allow(ENV).to receive(:[]).with("S3_BUCKET").and_return(nil)
        # Mock FileUtils to avoid errors in ensure block
        allow(FileUtils).to receive(:rm_f)
      end

      it "raises an error with missing config vars" do
        expect { service.perform }.to raise_error(RuntimeError, /Missing S3 config: S3_BUCKET/)
      end
    end

    context "when multiple config vars are missing" do
      before do
        allow(ENV).to receive(:[]).with("S3_BUCKET").and_return(nil)
        allow(ENV).to receive(:[]).with("S3_ENDPOINT").and_return(nil)
        # Mock FileUtils to avoid errors in ensure block
        allow(FileUtils).to receive(:rm_f)
      end

      it "lists all missing variables" do
        expect { service.perform }.to raise_error(RuntimeError, "Missing S3 config: S3_ENDPOINT, S3_BUCKET")
      end
    end

    context "with valid S3 configuration" do
      let(:temp_backup_path) { temp_dir.join(backup_filename) }
      let(:temp_compressed_path) { temp_dir.join(compressed_filename) }

      before do
        # Default stub for any system calls
        allow(service).to receive(:system).and_return(true)
        
        # Mock database backup creation
        allow(service).to receive(:system).with(
          "sqlite3",
          anything,
          /\.backup/,
          exception: true
        ).and_return(true)

        # Mock tar compression
        mock_tar_compression(service)

        # Mock S3 upload
        allow(s3_service).to receive(:upload)

        # Mock cleanup
        allow(bucket).to receive(:objects).with(prefix: "db_backups/").and_return([])
      end

      it "creates a database backup" do
        expect(service).to receive(:system).with(
          "sqlite3",
          anything,
          /\.backup.*database-2024-01-15\.sqlite3/,
          exception: true
        )

        service.perform
      end

      it "compresses the backup" do
        expect(service).to receive(:system).with(
          "tar", "-czf", /database-2024-01-15\.tar\.gz/,
          "-C", anything, "database-2024-01-15.sqlite3",
          exception: true
        )

        service.perform
      end

      it "uploads the compressed backup to S3" do
        expect(s3_service).to receive(:upload) do |key, file|
          expect(key).to eq(s3_key)
          expect(file).to be_a(File)
        end

        service.perform
      end

      it "returns success with backup details" do
        result = service.perform

        expect(result[:success]).to be true
        expect(result[:location]).to eq(s3_key)
        expect(result[:size_mb]).to be_a(Float)
        expect(result[:deleted_count]).to eq(0)
      end

      it "logs the backup process" do
        expect(Rails.logger).to receive(:info).with("Creating database backup...")
        expect(Rails.logger).to receive(:info).with("Database backup created successfully")
        expect(Rails.logger).to receive(:info).with("Compressing backup...")
        expect(Rails.logger).to receive(:info).with("Backup compressed successfully")
        expect(Rails.logger).to receive(:info).with("Uploading to S3 (#{s3_key})...")
        expect(Rails.logger).to receive(:info).with("Backup uploaded to S3 successfully")
        expect(Rails.logger).to receive(:info).with("Cleaning up old backups...")
        expect(Rails.logger).to receive(:info).with("Database backup completed successfully!")
        expect(Rails.logger).to receive(:info).with("Backup location: #{s3_key}")
        expect(Rails.logger).to receive(:info).with(/Backup size: \d+\.\d+ MB/)

        service.perform
      end

      context "when old backups exist" do
        let(:old_backup) do
          double(
            key: "db_backups/database-2023-10-01.tar.gz",
            last_modified: Time.zone.parse("2023-10-01")
          )
        end
        let(:recent_backup) do
          double(
            key: "db_backups/database-2024-01-10.tar.gz",
            last_modified: Time.zone.parse("2024-01-10")
          )
        end

        before do
          allow(bucket).to receive(:objects).with(prefix: "db_backups/")
            .and_return([old_backup, recent_backup])
          allow(s3_service).to receive(:delete)
        end

        it "deletes old backups" do
          expect(s3_service).to receive(:delete).with(old_backup.key)
          expect(s3_service).not_to receive(:delete).with(recent_backup.key)

          service.perform
        end

        it "returns the count of deleted backups" do
          allow(s3_service).to receive(:delete)

          result = service.perform
          expect(result[:deleted_count]).to eq(1)
        end

        it "logs when old backups are deleted" do
          allow(s3_service).to receive(:delete)
          # Allow all logger messages
          allow(Rails.logger).to receive(:info)
          # Expect the specific deletion message
          expect(Rails.logger).to receive(:info).with("Deleted 1 old backups")

          service.perform
        end
      end

      context "when no old backups exist" do
        it "does not log deletion message" do
          expect(Rails.logger).not_to receive(:info).with(/Deleted \d+ old backups/)

          service.perform
        end
      end

      context "when database backup fails" do
        before do
          allow(service).to receive(:system).and_return(true)
          allow(service).to receive(:system).with(
            "sqlite3",
            anything,
            /\.backup/,
            exception: true
          ).and_raise(StandardError, "Backup failed")
        end

        it "raises an error" do
          expect { service.perform }.to raise_error(StandardError, "Backup failed")
        end

        it "cleans up temp files in ensure block" do
          begin
            service.perform
          rescue
            # Expected error
          end

          # The ensure block should have cleaned up
          expect(File.exist?(temp_backup_path)).to be false
        end
      end

      context "when compression fails" do
        before do
          allow(service).to receive(:system).and_return(true)
          allow(service).to receive(:system).with(
            "sqlite3",
            anything,
            /\.backup/,
            exception: true
          ).and_return(true)
          allow(service).to receive(:system).with(
            "tar", "-czf", anything,
            "-C", anything, anything,
            exception: true
          ).and_raise(StandardError, "Compression failed")

          # Create the backup file that would exist before compression
          FileUtils.touch(temp_backup_path)
        end

        it "raises an error" do
          expect { service.perform }.to raise_error(StandardError, "Compression failed")
        end

        it "cleans up temp files in ensure block" do
          begin
            service.perform
          rescue
            # Expected error
          end

          # The ensure block should have cleaned up
          expect(File.exist?(temp_backup_path)).to be false
        end
      end

      context "when S3 upload fails" do
        before do
          allow(s3_service).to receive(:upload).and_raise(StandardError, "Upload failed")
        end

        it "raises an error" do
          expect { service.perform }.to raise_error(StandardError, "Upload failed")
        end

        it "cleans up temp files in ensure block" do
          begin
            service.perform
          rescue
            # Expected error
          end

          # The ensure block should have cleaned up
          expect(File.exist?(temp_backup_path)).to be false
          expect(File.exist?(temp_compressed_path)).to be false
        end
      end

      context "when cleanup fails" do
        before do
          allow(bucket).to receive(:objects).and_raise(StandardError, "Cleanup failed")
        end

        it "raises an error" do
          expect { service.perform }.to raise_error(StandardError, "Cleanup failed")
        end

        it "still cleans up temp files in ensure block" do
          begin
            service.perform
          rescue
            # Expected error
          end

          # The ensure block should have cleaned up
          expect(File.exist?(temp_backup_path)).to be false
          expect(File.exist?(temp_compressed_path)).to be false
        end
      end
    end

    context "with different timestamp formats" do
      it "uses the current timestamp in the filename" do
        allow(Time).to receive(:current).and_return(Time.zone.parse("2025-12-31 23:59:59"))

        expected_backup = "database-2025-12-31.sqlite3"
        expected_compressed = "database-2025-12-31.tar.gz"
        expected_s3_key = "db_backups/database-2025-12-31.tar.gz"

        temp_backup_path = temp_dir.join(expected_backup)
        temp_compressed_path = temp_dir.join(expected_compressed)

        # Default stub
        allow(service).to receive(:system).and_return(true)
        
        allow(service).to receive(:system).with(
          "sqlite3",
          anything,
          /\.backup.*database-2025-12-31\.sqlite3/,
          exception: true
        ).and_return(true)

        # Mock tar compression
        mock_tar_compression(service)
        allow(s3_service).to receive(:upload)
        allow(bucket).to receive(:objects).and_return([])

        result = service.perform
        expect(result[:location]).to eq(expected_s3_key)
      end
    end

    context "with edge cases in cleanup" do
      let(:temp_backup_path) { temp_dir.join(backup_filename) }
      let(:temp_compressed_path) { temp_dir.join(compressed_filename) }

      before do
        # Default stub for any system calls
        allow(service).to receive(:system).and_return(true)
        
        # Mock database backup creation
        allow(service).to receive(:system).with(
          "sqlite3",
          anything,
          /\.backup/,
          exception: true
        ).and_return(true)

        # Mock tar compression
        mock_tar_compression(service)
        
        allow(s3_service).to receive(:upload)
      end

      it "handles non-matching files in backup directory" do
        non_backup = double(
          key: "db_backups/README.md",
          last_modified: Time.zone.parse("2023-01-01")
        )
        invalid_format = double(
          key: "db_backups/database-invalid.zip",
          last_modified: Time.zone.parse("2023-01-01")
        )

        allow(bucket).to receive(:objects).with(prefix: "db_backups/")
          .and_return([non_backup, invalid_format])

        expect(s3_service).not_to receive(:delete)

        result = service.perform
        expect(result[:deleted_count]).to eq(0)
      end

      it "only deletes backups matching the expected pattern" do
        valid_old = double(
          key: "db_backups/database-2023-10-01.tar.gz",
          last_modified: Time.zone.parse("2023-10-01")
        )
        invalid_pattern = double(
          key: "db_backups/backup-2023-10-01.tar.gz",
          last_modified: Time.zone.parse("2023-10-01")
        )

        allow(bucket).to receive(:objects).with(prefix: "db_backups/")
          .and_return([valid_old, invalid_pattern])

        expect(s3_service).to receive(:delete).with(valid_old.key).once
        expect(s3_service).not_to receive(:delete).with(invalid_pattern.key)

        result = service.perform
        expect(result[:deleted_count]).to eq(1)
      end
    end
  end
end
