# frozen_string_literal: true

require "parallel_rspec"

namespace :test do
  desc "Run all tests in parallel excluding JavaScript tests (js: true)"
  ParallelRSpec::RakeTask.new(:no_js) do |t|
    t.pattern = "spec/**/*_spec.rb"
    t.rspec_opts = "--tag ~js:true"
  end
  
  desc "Run all tests in parallel (Docker-friendly version without JavaScript tests)"
  task :docker => :no_js
end