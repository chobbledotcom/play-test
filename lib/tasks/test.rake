# frozen_string_literal: true

# Only load if parallel_rspec is available
begin
  require "parallel_rspec"

  namespace :test do
    desc "Run all tests in parallel excluding JavaScript tests (js: true)"
    ParallelRSpec::RakeTask.new(:no_js) do |t|
      t.pattern = "spec/**/*_spec.rb"
      t.rspec_opts = "--tag ~js:true"
    end

    desc "Run all tests in parallel (Docker-friendly version without JavaScript tests)"
    task docker: :no_js
  end
rescue LoadError
  # parallel_rspec is not available (e.g., in development/production without test group)
  # This is expected, so we silently skip defining these tasks
end
