# typed: false
# frozen_string_literal: true

require "rails_helper"

# Drives the whole wizard question flow with scripted answers, a real
# BunnyClient behind a fake transport, and fakes for the restore and
# litestream seeding, asserting the exact container the wizard builds.
RSpec.describe MagicContainer::Wizard do
  subject(:wizard) { described_class.new(prompts: prompts) }

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
  let(:responses) do
    {
      "/apps" => {"id" => 42},
      "/apps/42/deploy" => {},
      "/apps/42/endpoints" => {"items" => [{"publicHost" => "mc-123.bunny.run", "containerId" => "c-9"}]},
      "/apps/42/containers/c-9/env" => {},
      "/registries" => {"items" => [{"displayName" => "Docker Hub", "hostName" => "docker.io", "id" => 7}]},
      "/regions/optimal" => {"region" => {"id" => "LDN"}}
    }
  end
  let(:transport) do
    lambda { |method, path, body|
      calls << {method: method, path: path, body: body}
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
        {restored_databases: ["production.sqlite3"]}
      end
    end
  end

  let!(:seeder) { instance_double(MagicContainer::LitestreamSeeder, call: true) }

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

    seeded_root = Pathname.new(
      Dir.glob(Rails.root.join("tmp/magic-container-*").to_s).first
    )
    expect(@seeder_kwargs[:db_path]).to eq(seeded_root.join("production.sqlite3"))
    expect(@seeder_kwargs[:replica_path]).to eq("production.sqlite3")

    s3 = @seeder_kwargs.fetch(:s3)
    expect(s3.access_key_id).to eq("ls-key")
    expect(s3.bucket).to eq("ls-bucket")
    expect(s3.endpoint).to eq("https://ls.example.com")
    expect(s3.region).to eq("us-east-1")
    expect(s3.secret_access_key).to eq("ls-secret")
    expect(seeder).to have_received(:call)
  end

  it "creates the application with the container, volume and endpoint" do
    wizard.call

    create_call = calls.find { it[:path] == "/apps" }
    body = create_call.fetch(:body)
    container = body.fetch(:containerTemplates).first
    expect(container).to include(
      endpoints: [{
        cdn: {isSslEnabled: false, portMappings: [{containerPort: 3000}]},
        displayName: "web"
      }],
      imageName: "play-test",
      imageNamespace: "chobble",
      imageRegistryId: "7",
      imageTag: "latest",
      volumeMounts: [{mountPath: "/rails/storage", name: "storage"}]
    )
    expect(body).to include(
      name: "play-test",
      regionSettings: {requiredRegionIds: ["LDN"]},
      runtimeType: "shared",
      volumes: [{name: "storage", size: 5}]
    )
  end

  it "populates the container environment from the answers" do
    wizard.call

    create_call = calls.find { it[:path] == "/apps" }
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

    it "keeps the given base url and skips the env update" do
      wizard.call

      expect(calls).not_to include(hash_including(path: "/apps/42/containers/c-9/env"))
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

      create_call = calls.find { it[:path] == "/apps" }
      body = create_call.fetch(:body)
      container = body.fetch(:containerTemplates).first
      expect(container).not_to have_key(:volumeMounts)
      expect(body).not_to have_key(:volumes)
    end
  end
end
