# typed: false

namespace :actionlint do
  desc "Run actionlint to check GitHub Actions workflows"
  task :check do
    puts "Running actionlint on GitHub Actions workflows..."
    # Use nix-shell to run actionlint directly
    success = system("nix-shell -p actionlint --run 'actionlint'")

    if success
      puts "✓ All GitHub Actions workflows are valid!"
    else
      puts "✗ Found issues in GitHub Actions workflows"
      exit(1)
    end
  end

  desc "Run actionlint with verbose output"
  task :verbose do
    puts "Running actionlint with verbose output..."
    system("nix-shell -p actionlint --run 'actionlint -verbose'")
  end

  desc "Format actionlint output as JSON"
  task :json do
    system("nix-shell -p actionlint --run \"actionlint -format '{{json .}}'\"")
  end
end

# Add actionlint to code standards checks
namespace :code_standards do
  desc "Run all code standards checks including actionlint"
  task all_with_actions: [:check, "actionlint:check"] do
    puts "All code standards checks completed!"
  end
end
