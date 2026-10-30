# typed: false
# frozen_string_literal: true

require "json"

# Baseline ratchet: the merged coverage must stay above these thresholds.
# These are the new higher baseline; raise them when coverage improves.
COVERAGE_LINE_MINIMUM = 90
COVERAGE_BRANCH_MINIMUM = 72

namespace :coverage do
  desc "Run tests in parallel with coverage"
  task :parallel do
    # Run tests in parallel - SimpleCov will automatically merge results
    system("bundle exec parallel_rspec spec/")

    exit $?.exitstatus unless $?.success?

    Rake::Task["coverage:check"].invoke
  end

  desc "Check merged coverage meets the baseline ratchet"
  task :check do
    resultset_path = Rails.root.join("coverage/.resultset.json")
    unless File.exist?(resultset_path)
      abort "coverage/.resultset.json not found - run the test suite with coverage first"
    end

    merged = merge_resultsets(JSON.parse(File.read(resultset_path)))

    line_percent = percent(merged[:covered_lines], merged[:total_lines])
    branch_percent = percent(merged[:covered_branches], merged[:total_branches])

    puts "Merged line coverage: #{merged[:covered_lines]}/#{merged[:total_lines]} " \
      "(#{line_percent}%)"
    puts "Merged branch coverage: #{merged[:covered_branches]}/#{merged[:total_branches]} " \
      "(#{branch_percent}%)"
    puts "Ratchet: #{COVERAGE_LINE_MINIMUM}% lines, #{COVERAGE_BRANCH_MINIMUM}% branches"

    failures = []
    failures << "#{line_percent}% lines (minimum #{COVERAGE_LINE_MINIMUM}%)" if line_percent < COVERAGE_LINE_MINIMUM
    failures << "#{branch_percent}% branches (minimum #{COVERAGE_BRANCH_MINIMUM}%)" if branch_percent < COVERAGE_BRANCH_MINIMUM

    if failures.any?
      abort "Coverage below the baseline ratchet: #{failures.join(", ")}. " \
        "Add tests before lowering the thresholds."
    end
  end

  # Merges per-process resultsets: a line or branch is covered if any process
  # covered it. SimpleCov writes one command per parallel worker.
  define_method(:merge_resultsets) do |resultset|
    file_line_arrays = Hash.new { |h, k| h[k] = [] }
    file_branch_arrays = Hash.new { |h, k| h[k] = [] }

    resultset.each_value do |command|
      (command["coverage"] || {}).each do |file, file_data|
        next unless file_data.is_a?(Hash)

        lines = file_data["lines"]
        file_line_arrays[file] << lines if lines.is_a?(Array)

        branches = file_data["branches"]
        file_branch_arrays[file] << branches if branches.is_a?(Hash)
      end
    end

    covered_lines = 0
    total_lines = 0
    file_line_arrays.each do |_file, line_arrays|
      length = line_arrays.map(&:length).max
      length.times do |index|
        hits = line_arrays.filter_map { |array| array[index] }.compact
        next if hits.empty?

        total_lines += 1
        covered_lines += 1 if hits.any?(&:positive?)
      end
    end

    # Branch data is a nested hash: {group => {"branch_id" => hit_count}}.
    # Merge by branch id across processes, taking the max hit count: a branch
    # is covered if any process covered it.
    covered_branches = 0
    total_branches = 0
    file_branch_arrays.each do |_file, branch_hashes|
      merged = {}
      branch_hashes.each do |branches|
        branches.each_value do |inner|
          next unless inner.is_a?(Hash)

          inner.each do |branch_id, hits|
            merged[branch_id] = [merged[branch_id].to_i, hits.to_i].max
          end
        end
      end
      merged.each_value do |hits|
        total_branches += 1
        covered_branches += 1 if hits.positive?
      end
    end

    {
      covered_lines: covered_lines,
      total_lines: total_lines,
      covered_branches: covered_branches,
      total_branches: total_branches
    }
  end

  define_method(:percent) do |covered, total|
    return 0.0 if total.zero?

    (covered * 100.0 / total).round(2)
  end
end
