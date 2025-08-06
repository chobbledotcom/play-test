#\!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script
# Optimized for Ubuntu 24.04 - runs on every sandbox start

# Skip if already set up (optimization for repeated runs)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    echo "Setup already complete. Run with FORCE_SETUP=1 to re-run."
    exit 0
fi

echo "Installing Ruby and dependencies..."
sudo apt-get update -qq
sudo apt-get install -y ruby-full ruby-bundler build-essential cmake pkg-config libsqlite3-dev libyaml-dev libvips-dev cmake pkg-config sassc

echo "Installing bundler gem..."
sudo gem install bundler

# Install Rails dependencies with bundler
echo "Installing gems..."
bundle install --jobs 4

# Database setup (only if not exists)
if [ \! -f "storage/development.sqlite3" ]; then
    echo "Creating development database..."
    bundle exec rails db:create db:migrate db:seed
fi

# Test database setup (only if not exists)
if [ \! -f "storage/test.sqlite3" ]; then
    echo "Creating test database..."
    RAILS_ENV=test bundle exec rails db:create db:migrate
    bundle exec rails parallel:prepare
fi

# Mark setup as complete
touch .terragon-setup-complete

echo "Rails setup complete\!"
