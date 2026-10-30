# typed: false
# frozen_string_literal: true

# Single source of truth for SimpleCov setup, shared by the test suite
# (spec/spec_helper.rb) and the coverage ratchet check (lib/coverage_ratchet.rb)
# so the ratchet measures exactly what the published report measures. Required
# directly by spec_helper before Rails boots, so it must not depend on Rails or
# Zeitwerk autoloading.
module SimplecovSetup
  CONFIGURE = lambda do
    skip "/spec/"
    skip "/config/"
    skip "/vendor/"
    skip "/db/seeds/"
    skip "db/seeds.rb"

    # Enable branch coverage for better insights
    enable_coverage :branch

    # Per-process floor for parallel runs: SimpleCov evaluates this against
    # each worker's merged subset, so it stays low. The real coverage gate
    # is the coverage:check ratchet (enforced by rake coverage:parallel).
    minimum_coverage 25

    # The suite can run longer than SimpleCov's default ten minute merge
    # window, so entries from workers that finished early must still count,
    # both in the workers' own merged report and in coverage:check.
    merge_timeout 3600

    # Configure for parallel tests - SimpleCov handles this automatically
    if ENV["TEST_ENV_NUMBER"]
      command_name "RSpec-#{ENV["TEST_ENV_NUMBER"]}"
    end
  end

  class << self
    # Start measuring coverage in a test process.
    def start
      SimpleCov.start "rails", &CONFIGURE
    end

    # Apply the same profile and filters in a process that only merges existing
    # results (coverage:check) and must not profile itself: SimpleCov.start
    # would begin measuring the rake process and write its own resultset entry.
    def apply_to_merger
      SimpleCov.load_profile "rails"
      SimpleCov.configure(&CONFIGURE)
    end
  end
end
