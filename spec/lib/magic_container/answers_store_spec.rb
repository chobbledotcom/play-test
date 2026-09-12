# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe MagicContainer::AnswersStore do
  subject(:store) { described_class.new(path: store_path) }

  let(:store_path) { Pathname.new(workdir).join(".env.magic_container") }
  let(:workdir) { Dir.mktmpdir("answers-store-spec") }
  let(:archive) { Pathname.new(workdir).join("backup-2026-01-01.tar.gz") }
  let(:answers) do
    MagicContainer::Answers.new(
      access_key: "bunny-key",
      app_name: "play-test",
      archive_path: archive,
      region: "LDN",
      runtime_type: "shared",
      registry_id: "7",
      image_ref: "chobble/play-test",
      image_tag: "latest",
      volume: true,
      volume_size_gb: 5,
      storage_s3: storage_s3,
      litestream_s3: litestream_s3,
      display_app_name: "Play-Test",
      base_url: "",
      rails_master_key: "",
      sentry_dsn: "",
      secret_key_base: "a" * 128
    )
  end
  let(:storage_s3) do
    MagicContainer::S3Details.new(
      access_key_id: "as-key",
      bucket: "as-bucket",
      endpoint: "https://as.example.com",
      region: "us-east-1",
      secret_access_key: "as secret #1"
    )
  end
  let(:litestream_s3) do
    MagicContainer::S3Details.new(
      access_key_id: "ls-key",
      bucket: "ls-bucket",
      endpoint: "https://ls.example.com",
      region: "ldn",
      secret_access_key: "ls-secret"
    )
  end

  before { File.write(archive, "tar") }

  after { FileUtils.rm_rf(workdir) }

  describe "#load" do
    it "returns nil when no answers have been saved" do
      expect(store.load).to be_nil
    end

    it "round-trips every answer, including a secret with spaces" do
      store.save(answers)
      loaded = store.load

      expect(loaded.access_key).to eq("bunny-key")
      expect(loaded.app_name).to eq("play-test")
      expect(loaded.archive_path).to eq(archive)
      expect(loaded.region).to eq("LDN")
      expect(loaded.runtime_type).to eq("shared")
      expect(loaded.registry_id).to eq("7")
      expect(loaded.image_ref).to eq("chobble/play-test")
      expect(loaded.image_tag).to eq("latest")
      expect(loaded.volume).to be true
      expect(loaded.volume_size_gb).to eq(5)
      expect(loaded.storage_s3.secret_access_key).to eq("as secret #1")
      expect(loaded.storage_s3.bucket).to eq("as-bucket")
      expect(loaded.litestream_s3.secret_access_key).to eq("ls-secret")
      expect(loaded.display_app_name).to eq("Play-Test")
      expect(loaded.base_url).to eq("")
      expect(loaded.secret_key_base).to eq("a" * 128)
    end

    it "round-trips an app id recorded for retries" do
      store.save(answers.with(app_id: "42"))

      expect(store.load.app_id).to eq("42")
    end

    it "round-trips declined volumes and other booleans" do
      store.save(answers.with(volume: false))

      expect(store.load.volume).to be false
    end

    it "ignores comments and blank lines" do
      store.save(answers)
      content = store_path.read
      store_path.write("# a comment\n\n#{content}")

      expect(store.load.secret_key_base).to eq("a" * 128)
      expect(store.load.storage_s3.secret_access_key).to eq("as secret #1")
    end

    it "round-trips an empty answers file as nil" do
      store_path.write("")

      expect(store.load).to be_nil
    end
  end

  describe "#save" do
    it "writes owner-only permissions and git-ignored dotenv keys" do
      store.save(answers)

      expect(File.stat(store_path).mode.to_s(8)).to end_with("600")
      content = store_path.read
      expect(content).to include("MAGIC_BUNNY_ACCESS_KEY=bunny-key")
      expect(content).not_to include("MAGIC_APP_ID=")
    end
  end

  describe "default path" do
    it "is the repo root dotenv file" do
      expect(described_class.new.path)
        .to eq(Rails.root.join(".env.magic_container"))
    end
  end
end
