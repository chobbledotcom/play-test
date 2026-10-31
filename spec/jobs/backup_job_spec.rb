# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackupJob, type: :job do
  describe "#perform" do
    it "runs the backup service and logs success" do
      service = instance_double(BackupService)
      expect(BackupService).to receive(:new).and_return(service)
      expect(service).to receive(:perform).with(destination: "both")

      described_class.perform_now
    end

    it "passes the requested destination through" do
      service = instance_double(BackupService)
      expect(BackupService).to receive(:new).and_return(service)
      expect(service).to receive(:perform).with(destination: "local")

      described_class.perform_now("local")
    end
  end
end
