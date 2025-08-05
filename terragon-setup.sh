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
sudo apt-get install -y ruby-full ruby-bundler build-essential libsqlite3-dev libyaml-dev libvips-dev

echo "Installing bundler gem..."
sudo gem install bundler

# Install Rails dependencies with bundler
echo "Installing gems..."
bundle install --jobs 4

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    echo "BASE_URL=localhost:3000" > .env
    echo "SITE_NAME=Play-Test CI" >> .env
fi

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

