require "yaml"
require "json"

namespace :attributions do
  desc "Generate ATTRIBUTIONS.md from cached license data"
  task :generate do
    # Update license cache if config exists
    if File.exist?(".licensed.yml")
      system("bundle exec licensed cache")
    end

    # Collect all dependency information
    dependencies = Dir[".licenses/bundler/*.yml"].map do |file|
      data = YAML.load_file(file)
      {
        name: data["name"],
        version: data["version"],
        license: data["license"],
        homepage: data["homepage"],
        summary: data["summary"]
      }
    end.sort_by { |d| d[:name] }

    # Generate ATTRIBUTIONS.md
    File.open("ATTRIBUTIONS.md", "w") do |f|
      f.puts "# Third-Party Attributions"
      f.puts
      f.puts "This project uses the following open source dependencies:"
      f.puts
      f.puts "Generated on: #{Time.now.utc.strftime("%Y-%m-%d")}"
      f.puts "Total dependencies: #{dependencies.count}"
      f.puts
      f.puts "## Dependencies by License"
      f.puts

      # Group by license
      by_license = dependencies.group_by { |d| d[:license] }
      by_license.sort_by { |license, _| license.to_s }.each do |license, deps|
        f.puts "### #{license.upcase} (#{deps.count} dependencies)"
        f.puts
        deps.each do |dep|
          f.puts "- **#{dep[:name]}** v#{dep[:version]}"
          f.puts "  - #{dep[:summary]}" if dep[:summary]
          f.puts "  - Homepage: #{dep[:homepage]}" if dep[:homepage]
          f.puts
        end
      end
    end

    # Generate compact JSON for programmatic use
    File.open("attributions.json", "w") do |f|
      json_data = {
        generated_at: Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S"),
        total_dependencies: dependencies.count,
        dependencies: dependencies
      }
      f.puts JSON.pretty_generate(json_data)
    end

    lines = `wc -l ATTRIBUTIONS.md`.split.first
    puts "✓ Generated ATTRIBUTIONS.md with #{lines} lines"
    puts "✓ Generated attributions.json"
  end
end
