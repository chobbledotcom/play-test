namespace :locale do
  desc "Run tests and track locale key usage"
  task track_usage: :environment do
    puts "Starting locale key usage tracking..."
    puts "=" * 80

    # Enable tracking by setting environment variable
    ENV["I18N_TRACKING_ENABLED"] = "true"

    puts "Running test suite..."
    success = system("bin/rspec --format progress")

    results_file = Rails.root.join("tmp/i18n_tracking_results.json")
    if File.exist?(results_file)
      used_keys = JSON.parse(File.read(results_file))
      I18nUsageTracker.load_tracked_keys(used_keys)
      File.delete(results_file)
    else
      puts "Warning: No tracking results file found!"
    end

    # Generate report
    report = I18nUsageTracker.usage_report

    puts "\n" + "=" * 80
    puts "LOCALE KEY USAGE REPORT"
    puts "=" * 80
    puts "Total locale keys found: #{report[:total_keys]}"
    puts "Keys used in tests: #{report[:used_keys]}"
    puts "Unused keys: #{report[:unused_keys]}"
    puts "Usage percentage: #{report[:usage_percentage]}%"

    if report[:unused_keys] > 0
      puts "\n" + "-" * 80
      puts "POTENTIALLY UNUSED LOCALE KEYS:"
      puts "-" * 80

      # Group unused keys by top-level namespace
      grouped_keys = report[:unused_key_list].group_by { |key| key.split(".").first }

      grouped_keys.each do |namespace, keys|
        puts "\n#{namespace}:"
        keys.sort.each { |key| puts "  - #{key}" }
      end

      # Save detailed report to file
      report_file = Rails.root.join("tmp/unused_locale_keys.txt")
      File.write(report_file, report[:unused_key_list].sort.join("\n"))
      puts "\n" + "-" * 80
      puts "Full list saved to: #{report_file}"
    end

    puts "\n" + "=" * 80
    puts "Test suite #{success ? "passed" : "failed"}"
  end

  desc "Run tests with locale tracking and show only unused keys"
  task find_unused: :environment do
    puts "Finding unused locale keys..."

    # Enable tracking by setting environment variable
    ENV["I18N_TRACKING_ENABLED"] = "true"

    puts "Running test suite (this may take a while)..."
    system("bin/rspec --format progress > /dev/null 2>&1")

    results_file = Rails.root.join("tmp/i18n_tracking_results.json")
    if File.exist?(results_file)
      used_keys = JSON.parse(File.read(results_file))
      I18nUsageTracker.load_tracked_keys(used_keys)
      File.delete(results_file)
    else
      puts "Warning: No tracking results file found!"
    end

    # Generate report
    report = I18nUsageTracker.usage_report

    if report[:unused_keys] > 0
      puts "\nPOTENTIALLY UNUSED LOCALE KEYS (#{report[:unused_keys]} found):"
      puts "=" * 80

      report[:unused_key_list].sort.each { |key| puts key }

      # Save to file
      report_file = Rails.root.join("tmp/unused_locale_keys.txt")
      File.write(report_file, report[:unused_key_list].sort.join("\n"))
      puts "\nFull list saved to: #{report_file}"
    else
      puts "\nNo unused locale keys found!"
    end
  end

  desc "Check specific locale keys for usage"
  task :check_keys, [:pattern] => :environment do |t, args|
    require_relative "../i18n_usage_tracker"

    pattern = args[:pattern] || "*"

    puts "Checking locale keys matching pattern: #{pattern}"

    # Enable tracking
    I18nUsageTracker.reset!
    I18nUsageTracker.tracking_enabled = true

    puts "Running test suite..."
    system("bin/rspec --format progress > /dev/null 2>&1")

    # Disable tracking
    I18nUsageTracker.tracking_enabled = false

    # Filter keys by pattern
    all_keys = I18nUsageTracker.all_locale_keys.select { |k| File.fnmatch(pattern, k) }
    used_keys = I18nUsageTracker.used_keys.select { |k| File.fnmatch(pattern, k) }
    unused_keys = all_keys - used_keys

    puts "\nKeys matching '#{pattern}':"
    puts "Total: #{all_keys.size}"
    puts "Used: #{used_keys.size}"
    puts "Unused: #{unused_keys.size}"

    if unused_keys.any?
      puts "\nUnused keys:"
      unused_keys.sort.each { |key| puts "  - #{key}" }
    end
  end
end
