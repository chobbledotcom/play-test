# frozen_string_literal: true

require "open3"

# Runs erb_lint on files one at a time with progress output
# rubocop:disable Rails/Output
class ErbLintRunner
  def initialize(autocorrect: false, verbose: false)
    @autocorrect = autocorrect
    @verbose = verbose
    @processed = 0
    @total_violations = 0
    @failed_files = []
  end

  def run_on_all_files
    erb_files = find_erb_files
    puts "Found #{erb_files.length} ERB files to lint..."
    puts "=" * 80

    erb_files.each_with_index do |file, index|
      process_file(file, index + 1, erb_files.length)
    end

    print_summary
    @failed_files.empty?
  end

  def run_on_files(files)
    puts "Linting #{files.length} ERB files..."
    puts "=" * 80

    files.each_with_index do |file, index|
      process_file(file, index + 1, files.length)
    end

    print_summary
    @failed_files.empty?
  end

  private

  def find_erb_files
    patterns = ["**/*.erb", "**/*.html.erb"]
    exclude_dirs = ["vendor", "node_modules", "tmp", "public"]

    files = []
    patterns.each do |pattern|
      Dir.glob(Rails.root.join(pattern).to_s).each do |file|
        relative_path = file.sub(Rails.root.to_s + "/", "")
        next if exclude_dirs.any? { |dir| relative_path.start_with?(dir) }
        files << relative_path
      end
    end

    files.uniq.sort
  end

  def process_file(file, current, total)
    print "[#{current}/#{total}] #{file.ljust(60)} "
    $stdout.flush

    start_time = Time.now.to_f

    # Use Open3 for safer command execution
    cmd_args = ["bundle", "exec", "erb_lint", file]
    cmd_args << "--autocorrect" if @autocorrect

    output, status = Open3.capture2e(*cmd_args)
    success = status.success?
    elapsed = (Time.now.to_f - start_time).round(2)

    if success
      puts "✅ (#{elapsed}s)"
    else
      violations = extract_violation_count(output)
      @total_violations += violations
      @failed_files << {file:, violations:, output:}

      # Show slow linter warning if it took too long
      if elapsed > 5.0
        puts "❌ #{violations} violation(s) (#{elapsed}s) ⚠️  SLOW"
        if @verbose
          puts "  Slow file details:"
          puts output.lines.grep(/\A\s*\d+:\d+/).first(3).map { |line| "    #{line.strip}" }
        end
      else
        puts "❌ #{violations} violation(s) (#{elapsed}s)"
      end
    end

    @processed += 1
  rescue => e
    puts "💥 Error: #{e.message}"
    @failed_files << {file:, violations: 0, output: e.message}
  end

  def extract_violation_count(output)
    # erb_lint output format: "1 error(s) were found"
    match = output.match(/(\d+) error\(s\) were found/)
    match ? match[1].to_i : 1
  end

  def print_summary
    puts "=" * 80
    puts "\nSUMMARY:"
    puts "Processed: #{@processed} files"
    puts "Failed: #{@failed_files.length} files"
    puts "Total violations: #{@total_violations}"

    if @failed_files.any?
      puts "\nFailed files:"
      @failed_files.each do |failure|
        puts "  #{failure[:file]} (#{failure[:violations]} violation(s))"
      end

      if !@autocorrect
        puts "\nTo fix these issues, run:"
        puts "  rake code_standards:erb_lint_fix"
      end
    else
      puts "\n✅ All ERB files passed linting!"
    end
  end
end
# rubocop:enable Rails/Output
