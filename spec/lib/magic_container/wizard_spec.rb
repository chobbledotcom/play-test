# typed: false
# frozen_string_literal: true

require "rails_helper"

# Drives the whole wizard question flow with scripted answers, a real
# BunnyClient behind a fake transport, and fakes for the restore and
# litestream seeding, asserting the exact container the wizard builds.
RSpec.describe MagicContainer::Wizard do
  subject(:wizard) { described_class.new(prompts: prompts, store: store) }

  let(:prompts) do
    MagicContainer::Prompts.new(
      input: StringIO.new(answers.join("\n")),
      output: output
    )
  end
  let(:output) { StringIO.new }
  let(:workdir) { Pathname.new(Dir.mktmpdir("wizard-spec")) }
  let(:archive_filename) { "backup-2026-01-01.tar.gz" }
  let(:archive_path) { workdir.join(archive_filename) }
  let(:store) { MagicContainer::AnswersStore.new(path: store_path) }
  let(:store_path) { workdir.join(".env.magic_container") }

  let(:answers) do
    [
      "bunny-key", # bunny api key
      "", # app name (default play-test)
      archive_path.to_s, # backup archive path
      "y", # use optimal region
      "", # registry (default first)
      "", # image (default chobble/play-test)
      "", # tag (default latest)
      "", # runtime (default shared)
      "", # attach volume (default yes)
      "", # volume size (default 5)
      "https://as.example.com", # storage endpoint
      "as-bucket", # storage bucket
      "", # storage region (default us-east-1)
      "as-key", # storage access key
      "as-secret", # storage secret key
      "https://ls.example.com", # litestream endpoint
      "ls-bucket", # litestream bucket
      "", # litestream region (default us-east-1)
      "ls-key", # litestream access key
      "ls-secret", # litestream secret key
      "", # display app name (default)
      "", # base url (blank, set from container url)
      "", # rails master key (blank)
      "", # sentry dsn (blank)
      "y" # confirm the plan
    ]
  end

  let(:calls) { [] }
  let(:existing_apps) { [] }
  let(:responses) do
    {
      "/apps" => {"id" => 42},
      "/apps/42/deploy" => {},
      "/apps/42/endpoints" => {
        "items" => [{"publicHost" => "mc-123.bunny.run", "containerId" => "c-9"}]
      },
      "/apps/42/containers/c-9/env" => {},
      "/apps/42/restart" => {},
      "/registries" => {"items" => [{"displayName" => "Docker Hub", "hostName" => "docker.io", "id" => 7}]},
      "/regions/optimal" => {"region" => {"id" => "LDN"}}
    }
  end
  let(:transport) do
    lambda { |method, path, body|
      calls << {method: method, path: path, body: body}
      # POST /apps creates; GET /apps lists what already exists
      return {"items" => existing_apps} if method == :get && path == "/apps"

      responses.fetch(path)
    }
  end

  let!(:client) do
    bunny = MagicContainer::BunnyClient.new(access_key: "bunny-key", transport: transport)
    allow(MagicContainer::BunnyClient).to receive(:new)
      .with(access_key: "bunny-key").and_return(bunny)
    bunny
  end

  let!(:restore_service) do
    instance_double(RestoreService).tap do |service|
      allow(RestoreService).to receive(:new).and_return(service)
      allow(service).to receive(:perform) do |args|
        @restore_args = args
        args.fetch(:db_paths).each do |db_path|
          FileUtils.mkdir_p(db_path.dirname)
          File.write(db_path, "sqlite")
        end
        {
          restored_databases: ["production.sqlite3"],
          storage_files_skipped: 0,
          storage_files_uploaded: 1
        }
      end
    end
  end

  let!(:seeder) do
    instance_double(MagicContainer::LitestreamSeeder, call: true)
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BUNNY_ACCESS_KEY").and_return(nil)
    allow(MagicContainer::LitestreamSeeder).to receive(:new).and_return(seeder)

    staging = workdir.join("staging")
    FileUtils.mkdir_p(staging.join("db"))
    File.write(staging.join("db/production.sqlite3"), "sqlite")
    system("tar", "-czf", archive_path.to_s, "-C", staging.to_s, "db", exception: true)
  end

  after do
    FileUtils.rm_rf(workdir)
    FileUtils.rm_rf(Dir.glob(Rails.root.join("tmp/magic-container*").to_s))
  end

  it "restores the backup into a working directory targetting the S3 service" do
    wizard.call

    expect(@restore_args).to include(
      archive_dir: workdir,
      date: "2026-01-01",
      service_name: "s3_host",
      skip_existing_uploads: true,
      storage_target: :s3
    )
    db_paths = @restore_args.fetch(:db_paths)
    expect(db_paths.map(&:basename).map(&:to_s)).to eq(["production.sqlite3"])
  end

  it "seeds the production database into the litestream replica" do
    allow(MagicContainer::LitestreamSeeder).to receive(:new).and_wrap_original do |_method, kwargs|
      @seeder_kwargs = kwargs
      seeder
    end

    wizard.call

    # Not via Dir.glob: leftover workdirs from real wizard runs in tmp make
    # "the first matching directory" unpredictable.
    db_path = @seeder_kwargs.fetch(:db_path)
    expect(db_path.dirname.to_s)
      .to start_with(Rails.root.join("tmp/magic-container-").to_s)
    expect(db_path.basename.to_s).to eq("production.sqlite3")
    expect(@seeder_kwargs[:replica_path]).to eq("production.sqlite3")

    s3 = @seeder_kwargs.fetch(:s3)
    expect(s3.access_key_id).to eq("ls-key")
    expect(s3.bucket).to eq("ls-bucket")
    expect(s3.endpoint).to eq("https://ls.example.com")
    expect(s3.region).to eq("us-east-1")
    expect(s3.secret_access_key).to eq("ls-secret")
    expect(seeder).to have_received(:call)
  end

  it "records the seeded replica path in the answers store" do
    wizard.call

    expect(store_path.read).to include("MAGIC_SEEDED_REPLICA_PATHS=production.sqlite3")
  end

  it "creates the application with the container, volume and endpoint" do
    wizard.call

    create_call = calls.find { it[:method] == :post && it[:path] == "/apps" }
    body = create_call.fetch(:body)
    container = body.fetch(:containerTemplates).first
    expect(container).to include(
      endpoints: [{
        cdn: {isSslEnabled: false, portMappings: [{containerPort: 3000}]},
        displayName: "web"
      }],
      imageName: "play-test",
      imageNamespace: "chobble",
      imagePullPolicy: "always",
      imageRegistryId: "7",
      imageTag: "latest",
      volumeMounts: [{mountPath: "/rails/storage", name: "storage"}]
    )
    expect(body).to include(
      name: "play-test",
      regionSettings: {allowedRegionIds: ["LDN"], requiredRegionIds: ["LDN"]},
      runtimeType: "shared",
      volumes: [{name: "storage", size: 5}]
    )
  end

  it "populates the container environment from the answers" do
    wizard.call

    create_call = calls.find { it[:method] == :post && it[:path] == "/apps" }
    env = create_call.fetch(:body).fetch(:containerTemplates).first
      .fetch(:environmentVariables).to_h { it.values_at(:name, :value) }
    expect(env).to include(
      "LITESTREAM_S3_BUCKET" => "ls-bucket",
      "LITESTREAM_S3_ENDPOINT" => "https://ls.example.com",
      "S3_BUCKET" => "as-bucket",
      "S3_ENDPOINT" => "https://as.example.com",
      "USE_S3_STORAGE" => "true"
    )
    expect(env["SECRET_KEY_BASE"].length).to eq(128)
  end

  it "deploys and pushes the container url into the environment" do
    wizard.call

    expect(calls).to include(hash_including(method: :post, path: "/apps/42/deploy"))
    env_call = calls.find { it[:path] == "/apps/42/containers/c-9/env" }
    expect(env_call[:method]).to eq(:put)
    expect(env_call.fetch(:body)).to include("BASE_URL" => "https://mc-123.bunny.run")
    expect(calls).to include(hash_including(method: :post, path: "/apps/42/restart"))
  end

  it "saves an environment record and reports the url" do
    wizard.call

    env_file = Rails.root.join("tmp/magic-container/42.env")
    expect(env_file).to exist
    expect(File.stat(env_file).mode.to_s(8)).to end_with("600")
    expect(File.read(env_file)).to include("SECRET_KEY_BASE=")
    expect(output.string).to include("URL: https://mc-123.bunny.run")
  end

  context "when the archive path does not exist" do
    let(:answers) do
      list = super()
      list[2] = "/nonexistent/backup-2026-01-01.tar.gz"
      list
    end

    it "aborts before executing anything" do
      expect { wizard.call }.to raise_error(/Archive not found/)
      expect(calls).to be_empty
      expect(restore_service).not_to have_received(:perform)
    end
  end

  context "when the archive filename has no date" do
    let(:archive_filename) { "custom.tar.gz" }

    it "aborts when the date cannot be parsed" do
      expect { wizard.call }.to raise_error(/Cannot read a backup date/)
    end
  end

  context "when no container endpoint appears" do
    before do
      responses["/apps/42/endpoints"] = {"items" => []}
      allow(wizard).to receive(:sleep)
    end

    it "raises after polling" do
      expect { wizard.call }
        .to raise_error(/No container endpoint appeared for app 42/)

      polls = calls.count { it[:path] == "/apps/42/endpoints" }
      expect(polls).to eq(MagicContainer::Wizard::ENDPOINT_POLLS)
    end
  end

  context "when the user supplies a base url" do
    let(:answers) do
      list = super()
      list[21] = "https://example.com"
      list
    end

    it "keeps the given base url and pushes it to the container" do
      wizard.call

      expect(calls).to include(hash_including(path: "/apps/42/containers/c-9/env"))
      env_call = calls.find { it[:path] == "/apps/42/containers/c-9/env" }
      expect(env_call.fetch(:body)).to include("BASE_URL" => "https://example.com")
      expect(calls).to include(hash_including(method: :post, path: "/apps/42/restart"))
      env_file = Rails.root.join("tmp/magic-container/42.env")
      expect(File.read(env_file)).to include("BASE_URL=https://example.com")
    end
  end

  context "when the volume is declined" do
    let(:answers) do
      list = super()
      list[8] = "n"
      list
    end

    it "creates the container without a volume" do
      wizard.call

      create_call = calls.find { it[:method] == :post && it[:path] == "/apps" }
      body = create_call.fetch(:body)
      container = body.fetch(:containerTemplates).first
      expect(container).not_to have_key(:volumeMounts)
      expect(body).not_to have_key(:volumes)
    end
  end

  context "when a typed master key has the wrong format" do
    let(:answers) do
      list = super()
      list[22] = "9" * 64
      list.insert(23, "a" * 32)
      list
    end

    it "rejects the malformed key and accepts the retried one" do
      wizard.call

      expect(output.string)
        .to include("RAILS_MASTER_KEY must be 32 hexadecimal characters")
      create_call = calls.find { it[:method] == :post && it[:path] == "/apps" }
      env = create_call.fetch(:body).fetch(:containerTemplates).first
        .fetch(:environmentVariables).to_h { it.values_at(:name, :value) }
      expect(env["RAILS_MASTER_KEY"]).to eq("a" * 32)
    end
  end

  context "when a previous attempt saved its answers" do
    let(:retry_prompts) do
      MagicContainer::Prompts.new(
        input: StringIO.new(["y", "y"].join("\n")),
        output: retry_output
      )
    end
    let(:retry_output) { StringIO.new }

    before do
      wizard.call
      allow(restore_service).to receive(:perform) do |args|
        @restore_args = args
        args.fetch(:db_paths).each do |db_path|
          FileUtils.mkdir_p(db_path.dirname)
          File.write(db_path, "sqlite")
        end
        {
          restored_databases: ["production.sqlite3"],
          storage_files_skipped: 2,
          storage_files_uploaded: 0
        }
      end
      calls.clear
    end

    it "reuses the answers and skips completed work" do
      described_class.new(prompts: retry_prompts, store: store).call

      expect(retry_output.string).to include("Loaded answers from #{store_path}")
      expect(retry_output.string).to include("Skipped 2 Active Storage files")
      expect(retry_output.string).to include(
        I18n.t("magic_container.wizard.notes.seeded_skip", name: "production.sqlite3")
      )
      expect(retry_output.string).to include("Reusing app 42")

      expect(calls).not_to include(hash_including(method: :post, path: "/apps"))
      expect(calls).to include(hash_including(method: :post, path: "/apps/42/deploy"))
      expect(seeder).to have_received(:call).exactly(:once)
    end

    it "applies the final answers to the reused app before deploying" do
      described_class.new(prompts: retry_prompts, store: store).call

      # The retry loads the resolved base url, so the environment is rebuilt
      # from the answers and pushed to the reused app
      env_calls = calls.select { it[:path] == "/apps/42/containers/c-9/env" }
      expect(env_calls).to be_present
      expect(env_calls.first.fetch(:body)).to include(
        "BASE_URL" => "https://mc-123.bunny.run"
      )
      expect(calls).to include(hash_including(method: :post, path: "/apps/42/restart"))
    end

    it "keeps the app id in the answers file" do
      described_class.new(prompts: retry_prompts, store: store).call

      expect(store_path.read).to include("MAGIC_APP_ID=42")
    end
  end

  context "when an existing Bunny app already carries the answers' name" do
    let(:existing_apps) { [{"id" => 42, "name" => "play-test"}] }
    let(:orphan_prompts) do
      MagicContainer::Prompts.new(
        input: StringIO.new([*answers, "y"].join("\n")),
        output: orphan_output
      )
    end
    let(:orphan_output) { StringIO.new }

    it "offers the existing app for reuse instead of creating a duplicate" do
      described_class.new(prompts: orphan_prompts, store: store).call

      expect(orphan_output.string).to include("Reusing existing Bunny app 42")
      expect(calls).not_to include(hash_including(method: :post, path: "/apps"))
      expect(calls).to include(hash_including(method: :post, path: "/apps/42/deploy"))
      expect(store_path.read).to include("MAGIC_APP_ID=42")
    end
  end

  context "when the orphaned app is declined" do
    let(:existing_apps) { [{"id" => 42, "name" => "play-test"}] }
    let(:orphan_prompts) do
      MagicContainer::Prompts.new(
        input: StringIO.new([*answers, "n"].join("\n")),
        output: orphan_output
      )
    end
    let(:orphan_output) { StringIO.new }

    it "creates a fresh app" do
      described_class.new(prompts: orphan_prompts, store: store).call

      expect(calls.count { it[:method] == :post && it[:path] == "/apps" }).to eq(1)
      expect(store_path.read).to include("MAGIC_APP_ID=42")
    end
  end

  context "when several apps carry the answers' name" do
    let(:existing_apps) do
      [
        {"id" => 43, "name" => "play-test"},
        {"id" => 42, "name" => "play-test"}
      ]
    end
    let(:orphan_prompts) do
      MagicContainer::Prompts.new(
        input: StringIO.new([*answers, "2"].join("\n")),
        output: orphan_output
      )
    end
    let(:orphan_output) { StringIO.new }

    it "lets the operator pick which app to reuse" do
      described_class.new(prompts: orphan_prompts, store: store).call

      expect(calls).not_to include(hash_including(method: :post, path: "/apps"))
      expect(calls).to include(hash_including(method: :post, path: "/apps/42/deploy"))
      expect(store_path.read).to include("MAGIC_APP_ID=42")
    end
  end

  context "when several apps carry the answers' name and a fresh one is picked" do
    let(:existing_apps) do
      [
        {"id" => 43, "name" => "play-test"},
        {"id" => 44, "name" => "play-test"}
      ]
    end
    let(:orphan_prompts) do
      MagicContainer::Prompts.new(
        input: StringIO.new([*answers, "3"].join("\n")),
        output: orphan_output
      )
    end
    let(:orphan_output) { StringIO.new }

    it "creates a new app" do
      described_class.new(prompts: orphan_prompts, store: store).call

      expect(calls.count { it[:method] == :post && it[:path] == "/apps" }).to eq(1)
    end
  end

  context "when the stored master key is malformed" do
    let(:replenish_prompts) do
      MagicContainer::Prompts.new(
        input: StringIO.new(["y", "a" * 32, "y"].join("\n")),
        output: replenish_output
      )
    end
    let(:replenish_output) { StringIO.new }

    before do
      wizard.call
      store.save(store.load.with(rails_master_key: "9" * 64))
    end

    it "asks for a replacement and deploys it" do
      described_class.new(prompts: replenish_prompts, store: store).call

      expect(replenish_output.string)
        .to include("stored RAILS_MASTER_KEY is malformed")
      env_calls = calls.select { it[:path] == "/apps/42/containers/c-9/env" }
      expect(env_calls.last.fetch(:body)).to include("RAILS_MASTER_KEY" => "a" * 32)
      expect(store_path.read).to include("MAGIC_RAILS_MASTER_KEY=#{"a" * 32}")
    end
  end

  context "when previous answers exist but are declined" do
    let(:decline_prompts) do
      MagicContainer::Prompts.new(
        input: StringIO.new(["n", *answers, "y"].join("\n")),
        output: decline_output
      )
    end
    let(:decline_output) { StringIO.new }

    before { wizard.call }

    it "collects fresh answers and creates a new app" do
      calls.clear
      described_class.new(prompts: decline_prompts, store: store).call

      expect(decline_output.string).not_to include("Loaded answers from")
      expect(calls.count { it[:method] == :post && it[:path] == "/apps" }).to eq(1)
      expect(calls.count { it[:method] == :get && it[:path] == "/apps" }).to eq(1)
      expect(seeder).to have_received(:call).twice
    end
  end

  context "when previous answers point at a missing archive" do
    before do
      wizard.call
      FileUtils.rm_f(archive_path)
      calls.clear
    end

    it "aborts before executing anything" do
      retry_prompts = MagicContainer::Prompts.new(
        input: StringIO.new("y\n"), output: StringIO.new
      )
      expect { described_class.new(prompts: retry_prompts, store: store).call }
        .to raise_error(/Archive not found/)
      expect(calls).to be_empty
      expect(restore_service).to have_received(:perform).exactly(:once)
      expect(seeder).to have_received(:call).exactly(:once)
    end
  end
end
