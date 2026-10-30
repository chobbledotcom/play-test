# typed: false
# frozen_string_literal: true

# Rake runs task bodies without booting the Rails environment, so Zeitwerk
# never autoloads here; and environments with reloading disabled (production)
# never lazy-load either. Require explicitly instead.
require Rails.root.join("lib/simplecov_setup")
require Rails.root.join("lib/coverage_ratchet")

namespace :coverage do
  desc "Run tests in parallel with coverage, then enforce the baseline ratchet"
  task :parallel do
    # One ratchet check per run: start from an empty resultset so entries left
    # over from earlier runs of different code cannot pollute the merge (CI
    # checkouts start empty; local checkouts accumulate across days).
    resultset_path = Rails.root.join("coverage/.resultset.json")
    File.delete(resultset_path) if File.exist?(resultset_path)

    # Run tests in parallel - SimpleCov will automatically merge results
    system("bundle exec parallel_rspec spec/")

    # A signal kill or a spawn failure leaves no exit status; still exit nonzero
    exit($?.exitstatus || 1) unless $?.success?

    # reenable so `rake coverage:check coverage:parallel` cannot silently skip
    # the check because the task was already invoked once
    Rake::Task["coverage:check"].reenable
    Rake::Task["coverage:check"].invoke
  end

  desc "Check merged coverage meets the baseline ratchet"
  task :check do
    CoverageRatchet.verify(resultset_path: Rails.root.join("coverage/.resultset.json"))
  end
end
