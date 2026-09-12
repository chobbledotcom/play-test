# typed: false

require "spec_helper"
require "erb"
require "yaml"

RSpec.describe "Test database configuration" do
  let(:database_yaml) do
    File.read(File.expand_path("../../config/database.yml", __dir__))
  end
  let(:configuration) do
    -> { YAML.safe_load(ERB.new(database_yaml).result, aliases: true)["test"] }
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("IN_MEMORY_DB").and_return(nil)
  end

  it "defaults to WAL without shared cache" do
    config = configuration.call
    pid = Process.pid

    expect(config.fetch("database")).to eq("tmp/test-#{pid}.sqlite3")
    expect(config.fetch("pragmas").fetch("journal_mode")).to eq("wal")
  end

  it "isolates processes even without parallel worker numbers" do
    allow(Process).to receive(:pid).and_return(123, 456)
    paths = Array.new(2) { configuration.call.fetch("database") }

    expect(paths).to eq(["tmp/test-123.sqlite3", "tmp/test-456.sqlite3"])
  end

  it "selects shared memory at configuration load when explicitly requested" do
    allow(ENV).to receive(:[]).with("IN_MEMORY_DB").and_return("true")
    config = configuration.call

    expect(config.fetch("database")).to eq("file::memory:?cache=shared")
    expect(config.fetch("pragmas").fetch("journal_mode")).to eq("memory")
    expect(config.fetch("pragmas")).not_to have_key("mmap_size")
  end

  it "opts direct mutant runs into memory before loading Rails" do
    path = File.expand_path("../../config/mutant.yml", __dir__)
    config = YAML.safe_load_file(path)

    expect(config.fetch("environment_variables"))
      .to include("IN_MEMORY_DB" => "true", "RAILS_ENV" => "test")
  end
end
