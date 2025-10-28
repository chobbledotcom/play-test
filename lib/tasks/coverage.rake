# typed: false

namespace :coverage do
  desc "Run tests in parallel with coverage"
  task :parallel do
    # Run tests in parallel - SimpleCov will automatically merge results
    system("bundle exec parallel_rspec spec/")
  end
end
