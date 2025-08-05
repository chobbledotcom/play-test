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

  private

  def find_env_variables_in_codebase
    env_vars = Set.new

    search_in_directories(env_vars)
    search_in_bin_directory(env_vars)

    # Filter out common system/Rails variables that don't need documentation
    env_vars - system_env_variables
  end

  def system_env_variables
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

  def search_in_directories(env_vars)
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

  def search_files_by_pattern(path, pattern, env_vars)
    Dir.glob(File.join(path, "**", pattern)).each do |file|
      next if skip_file?(file)

      content = File.read(file)
      extract_env_vars_from_content(content, env_vars)
    end
  end

  def skip_file?(file)
    file.include?("/vendor/") ||
      file.include?("/node_modules/") ||
      file.include?("/tmp/") ||
      file.include?("/coverage/") ||
      file.include?("/spec/") ||
      file.include?("/test/")
  end

  def extract_env_vars_from_content(content, env_vars)
    # Match ENV["VAR"], ENV['VAR']
    content.scan(/ENV\[["']([^"']+)["']\]/).each do |match|
      env_vars.add(match[0])
    end

    # Match ENV.fetch("VAR"), ENV.fetch('VAR')
    content.scan(/ENV\.fetch\(["']([^"']+)["']/).each do |match|
      env_vars.add(match[0])
    end
  end

  def search_in_bin_directory(env_vars)
    Dir.glob(Rails.root.join("bin/*")).each do |file|
      next unless File.file?(file)
      content = File.read(file)
      extract_env_vars_from_content(content, env_vars)
    end
  end

  def parse_env_example_file
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
