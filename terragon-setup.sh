#\!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script
# Optimized for Ubuntu 24.04 - runs on every sandbox start

# Skip if already set up (optimization for repeated runs)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    echo "Setup already complete. Run with FORCE_SETUP=1 to re-run."
    exit 0
fi

echo "Installing aria2 for parallel downloads..."
sudo apt-get update -qq
sudo apt-get install -y aria2

echo "Installing apt-fast for faster package downloads..."
if ! command -v apt-fast &> /dev/null; then
    /bin/bash -c "$(curl -sL https://git.io/vokNn)"
fi

echo "Installing Ruby and dependencies..."
sudo apt-fast update -qq
# Use ruby3.4 package which provides Ruby 3.4.1 - close enough for test VM
sudo apt-fast install -y ruby3.4 ruby3.4-dev build-essential cmake pkg-config libsqlite3-dev libyaml-dev libvips-dev sassc

echo "Installing bundler gem..."
gem install bundler

# Configure bundler to exclude development, production, and CI-only gem groups
echo "Configuring bundler to skip development, production, and CI-only gems..."
bundle config set --local without 'development production ci_annotations ci_coverage'

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
