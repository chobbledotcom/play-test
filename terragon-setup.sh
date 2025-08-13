#\!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script
# Optimized for Ubuntu 24.04 - runs on every sandbox start

# Set PATH for ruby-install Ruby if it exists
if [ -d "$HOME/.rubies/ruby-3.4.3" ]; then
    export PATH="$HOME/.rubies/ruby-3.4.3/bin:$PATH"
fi

# Skip if already set up (optimization for repeated runs)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    echo "Setup already complete. Run with FORCE_SETUP=1 to re-run."
    exit 0
fi

echo "Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y build-essential cmake pkg-config libsqlite3-dev libyaml-dev libvips-dev sassc wget tar libssl-dev libreadline-dev zlib1g-dev

# Install ruby-install if not already present
if ! command -v ruby-install &> /dev/null; then
    echo "Installing ruby-install..."
    wget -q https://github.com/postmodern/ruby-install/releases/download/v0.10.1/ruby-install-0.10.1.tar.gz
    tar -xzf ruby-install-0.10.1.tar.gz
    cd ruby-install-0.10.1/
    sudo make install >/dev/null 2>&1
    cd ..
    rm -rf ruby-install-0.10.1*
fi

# Install Ruby 3.4.3 if not already installed
if [ ! -d "$HOME/.rubies/ruby-3.4.3" ]; then
    echo "Installing Ruby 3.4.3 (this may take a few minutes)..."
    ruby-install --no-install-deps ruby 3.4.3
fi

# Set up PATH for the installed Ruby
export PATH="$HOME/.rubies/ruby-3.4.3/bin:$PATH"

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
