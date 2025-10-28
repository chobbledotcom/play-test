# typed: false

require "rails_helper"

RSpec.describe "Environment Variables Documentation" do
  let(:env_example_path) { Rails.root.join(".env.example") }
  let(:env_variables_in_code) { find_env_variables_in_codebase }
  let(:env_variables_in_example) { parse_env_example_file }

  it "documents all ENV variables used in the codebase in .env.example" do
    missing_variables = env_variables_in_code - env_variables_in_example

    if missing_variables.any?
      error_message = "ENV variables missing from .env.example:\n" \
        "#{missing_variables.sort.map { |var| "  - #{var}" }.join("\n")}\n\n" \
        "Please add these variables to .env.example with comments."

      fail error_message
    end
  end

  it ".env.example file exists" do
    unless File.exist?(env_example_path)
      fail ".env.example file is missing. " \
        "Please create it to document environment variables."
    end
  end

  describe "Default environment variables" do
    it "provides defaults for BASE_URL and APP_NAME" do
      # Test that defaults are set when ENV vars are not present
      original_app_name = ENV["APP_NAME"]
      original_base_url = ENV["BASE_URL"]

      begin
        ENV.delete("APP_NAME")
        ENV.delete("BASE_URL")

        # Reload the initializer to test defaults
        load Rails.root.join("config/initializers/00_default_env_vars.rb")

        expect(ENV["APP_NAME"]).to eq("Play-Test")
        expect(ENV["BASE_URL"]).to eq("http://localhost:3000")
      ensure
        ENV["APP_NAME"] = original_app_name
        ENV["BASE_URL"] = original_base_url
      end
    end

    it "does not override existing values" do
      original_app_name = ENV["APP_NAME"]
      original_base_url = ENV["BASE_URL"]

      begin
        ENV["APP_NAME"] = "Custom App"
        ENV["BASE_URL"] = "https://example.com"

        # Reload the initializer
        load Rails.root.join("config/initializers/00_default_env_vars.rb")

        expect(ENV["APP_NAME"]).to eq("Custom App")
        expect(ENV["BASE_URL"]).to eq("https://example.com")
      ensure
        ENV["APP_NAME"] = original_app_name
        ENV["BASE_URL"] = original_base_url
      end
    end
  end

  private

  define_method(:find_env_variables_in_codebase) do
    env_vars = Set.new

    search_in_directories(env_vars)
    search_in_bin_directory(env_vars)

    # Filter out common system/Rails variables that don't need documentation
    env_vars - system_env_variables
  end

  define_method(:system_env_variables) do
    %w[
      BUNDLE_GEMFILE
      BUNDLER_VERSION
      CI
      PATH
      PORT
      PIDFILE
      RAILS_ENV
      RAILS_LOG_LEVEL
      RAILS_MASTER_KEY
      RAILS_MAX_THREADS
      RENDER_GIT_COMMIT
      TEST_ENV_NUMBER
      VAR
    ].to_set
  end

  define_method(:search_in_directories) do |env_vars|
    paths_to_search = %w[app config lib]
    file_patterns = %w[*.rb *.erb *.yml *.rake]

    paths_to_search.each do |path|
      full_path = Rails.root.join(path)
      next unless File.exist?(full_path)

      file_patterns.each do |pattern|
        search_files_by_pattern(full_path, pattern, env_vars)
      end
    end
  end

  define_method(:search_files_by_pattern) do |path, pattern, env_vars|
    Dir.glob(File.join(path, "**", pattern)).each do |file|
      next if skip_file?(file)

      content = File.read(file)
      extract_env_vars_from_content(content, env_vars)
    end
  end

  define_method(:skip_file?) do |file|
    file.include?("/vendor/") ||
      file.include?("/node_modules/") ||
      file.include?("/tmp/") ||
      file.include?("/coverage/") ||
      file.include?("/spec/") ||
      file.include?("/test/")
  end

  define_method(:extract_env_vars_from_content) do |content, env_vars|
    content.scan(/ENV\[["']([^"']+)["']\]/).each do |match|
      env_vars.add(match[0])
    end

    # Match ENV.fetch("VAR"), ENV.fetch('VAR')
    content.scan(/ENV\.fetch\(["']([^"']+)["']/).each do |match|
      env_vars.add(match[0])
    end
  end

  define_method(:search_in_bin_directory) do |env_vars|
    Rails.root.glob("bin/*").each do |file|
      next unless File.file?(file)
      content = File.read(file)
      extract_env_vars_from_content(content, env_vars)
    end
  end

  define_method(:parse_env_example_file) do
    return Set.new unless File.exist?(env_example_path)

    env_vars = Set.new

    File.readlines(env_example_path).each do |line|
      # Skip comments and empty lines
      next if line.strip.empty? || line.strip.start_with?("#")

      # Match VAR_NAME=value or VAR_NAME= patterns
      match = line.match(/^([A-Z_]+[A-Z0-9_]*)=/)
      env_vars.add(match[1]) if match
    end

    env_vars
  end
end
