# typed: false

require "spec_helper"
require "open3"
require "sqlite3"
require "tmpdir"

RSpec.describe "Test database safety" do
  %w[development test].each do |environment|
    it "refuses to overwrite an external database in #{environment}" do
      Dir.mktmpdir("test-database-safety") do |directory|
        database_path = File.join(directory, "external.sqlite3")
        SQLite3::Database.new(database_path) do |database|
          database.execute("CREATE TABLE users (marker TEXT)")
          database.execute("INSERT INTO users VALUES ('preserved')")
        end

        env = {
          "DATABASE_URL" => "sqlite3:#{database_path}",
          "DISABLE_SIMPLECOV" => "true",
          "IN_MEMORY_DB" => "false",
          "RAILS_ENV" => environment
        }
        _, stderr, status = Open3.capture3(
          env, RbConfig.ruby, "-rrspec/core", "-I", "spec",
          "-e", 'require "rails_helper"'
        )

        expect(status.exitstatus).to eq(1)
        expect(stderr).to include("Refusing to load the test schema")
        SQLite3::Database.new(database_path) do |database|
          expect(database.get_first_value("SELECT marker FROM users"))
            .to eq("preserved")
        end
      end
    end
  end
end
