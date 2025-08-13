# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe S3BackupOperations do
  let(:test_class) do
    Class.new do
      include S3BackupOperations
      public :backup_dir, :backup_retention_days, :temp_dir,
        :database_path, :create_tar_gz, :cleanup_old_backups
    end
  end

  let(:instance) { test_class.new }

  describe "#database_path" do
    it "handles multi-database config by using primary" do
      allow(Rails.configuration).to receive(:database_configuration).and_return({
        "test" => {
          "primary" => {"database" => "db/primary.sqlite3"},
          "queue" => {"database" => "db/queue.sqlite3"}
        }
      })

      expect(instance.database_path).to eq(Rails.root.join("db/primary.sqlite3"))
    end

    it "raises when database not configured" do
      allow(Rails.configuration).to receive(:database_configuration).and_return({
        "test" => {"adapter" => "sqlite3"}
      })

      expect { instance.database_path }.to raise_error("Database not configured for test")
    end
  end

  describe "#create_tar_gz" do
    let(:timestamp) { "2024-01-15" }
    let(:temp_dir) { Rails.root.join("tmp/backups") }

    before do
      FileUtils.mkdir_p(temp_dir)
      FileUtils.touch(temp_dir.join("database-#{timestamp}.sqlite3"))
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it "calls tar with constructed paths based on timestamp" do
      expected_dest = temp_dir.join("database-#{timestamp}.tar.gz")

      expect(instance).to receive(:system).with(
        "tar", "-czf", expected_dest.to_s,
        "-C", temp_dir.to_s, "database-#{timestamp}.sqlite3",
        exception: true
      ).and_return(true)

      expect(instance.create_tar_gz(timestamp)).to eq(expected_dest)
    end
  end

  describe "#cleanup_old_backups" do
    let(:service) { double("S3Service") }
    let(:bucket) { double("S3Bucket") }

    before do
      allow(Time).to receive(:current).and_return(Time.zone.parse("2024-01-15"))
      allow(service).to receive(:send).with(:bucket).and_return(bucket)
    end

    it "deletes backups older than retention period" do
      old_backup = double(key: "db_backups/database-2023-10-01.tar.gz",
        last_modified: Time.zone.parse("2023-10-01"))
      recent_backup = double(key: "db_backups/database-2024-01-10.tar.gz",
        last_modified: Time.zone.parse("2024-01-10"))
      non_backup = double(key: "db_backups/other.txt",
        last_modified: Time.zone.parse("2023-10-01"))

      allow(bucket).to receive(:objects).with(prefix: "db_backups/")
        .and_return([old_backup, recent_backup, non_backup])

      expect(service).to receive(:delete).with(old_backup.key).once

      expect(instance.cleanup_old_backups(service)).to eq(1)
    end
  end
end
