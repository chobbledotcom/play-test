actionlint - GitHub Actions Workflow Linter
==========================================

actionlint is a static checker for GitHub Actions workflow files.
It catches syntax errors, type errors, and other common mistakes.

Installation:
  ./bin/install-actionlint

Usage:
  # Check all workflows
  bin/actionlint
  
  # Or use rake tasks
  rake actionlint:check      # Run actionlint
  rake actionlint:verbose    # Run with verbose output
  rake actionlint:json       # Output as JSON
  rake actionlint:install    # Install/update actionlint

Configuration:
  .github/actionlint.yml     # Configuration file

The binary is installed to bin/actionlint and is gitignored.
To update to a newer version, edit ACTIONLINT_VERSION in bin/install-actionlint.

Documentation: https://github.com/rhysd/actionlint