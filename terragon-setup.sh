#!/bin/bash
set -euo pipefail

curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm

# Add nix to PATH
export PATH="$HOME/.nix-profile/bin:$PATH"

# Run bundle install inside nix develop shell
echo "Running bundle install in nix develop shell..."
nix develop --command 'MAKE="make --jobs 4" bundle install'

# Print instructions for Terry
echo ""
echo "================== TERRY INSTRUCTIONS =================="
echo "To run rspec tests with the nix shell, use:"
echo ""
echo "  nix develop --command bundle exec rspec"
echo ""
echo "Or enter the nix shell first and run commands:"
echo ""
echo "  nix develop"
echo "  bundle exec rspec"
echo ""
echo "The nix shell provides all required dependencies."
echo "========================================================"
