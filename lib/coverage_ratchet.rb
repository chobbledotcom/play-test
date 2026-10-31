# typed: false
# frozen_string_literal: true

# Baseline ratchet: the merged coverage must stay above these thresholds.
# These are the new higher baseline; raise them when coverage improves.
class CoverageRatchet
  LINE_MINIMUM = 90
  BRANCH_MINIMUM = 72

  class << self
    def verify(resultset_path:)
      unless File.exist?(resultset_path)
        abort "coverage/.resultset.json not found - run the test suite with coverage first"
      end

      merged = merge_resultset(resultset_path)
      line = merged.coverage_statistics[:line]
      branch = merged.coverage_statistics[:branch]

      puts "Merged line coverage: #{line.covered}/#{line.total} (#{rounded(line)}%)"
      puts "Merged branch coverage: #{branch.covered}/#{branch.total} (#{rounded(branch)}%)"
      puts "Ratchet: #{LINE_MINIMUM}% lines, #{BRANCH_MINIMUM}% branches"

      failures = missing_data_failures(line, branch)
      failures << "#{rounded(line)}% lines (minimum #{LINE_MINIMUM}%)" if line.percent < LINE_MINIMUM
      failures << "#{rounded(branch)}% branches (minimum #{BRANCH_MINIMUM}%)" if branch.percent < BRANCH_MINIMUM

      if failures.any?
        abort "Coverage below the baseline ratchet: #{failures.join(", ")}. " \
          "Add tests before lowering the thresholds."
      end
    end

    private

    # SimpleCov reports an empty criterion as a vacuous 100%, which would fail
    # open, so a resultset without line or branch tables is a failure.
    def missing_data_failures(line, branch)
      failures = []
      failures << "no line coverage data found in the resultset" if line.total.zero?
      failures << "no branch coverage data found in the resultset" if branch.total.zero?
      failures
    end

    # Merge through SimpleCov's own combiner so the ratchet measures exactly
    # what the published HTML report measures: same branch matching, same
    # merge_timeout handling for entries left over from earlier runs.
    def merge_resultset(resultset_path)
      require "simplecov"
      SimplecovSetup.apply_to_merger
      merged = SimpleCov::ResultMerger.merge_results(resultset_path.to_s)
      abort "No coverage data found in #{resultset_path}" if merged.nil?
      merged
    end

    def rounded(statistics) = statistics.percent.round(2)
  end
end
