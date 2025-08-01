#\!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script
# Optimized for Ubuntu 24.04 - runs on every sandbox start

# Skip if already set up (optimization for repeated runs)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    echo "Setup already complete. Run with FORCE_SETUP=1 to re-run."
    exit 0
fi

echo "Setting up Rails environment..."

# Check if Ruby is installed
if \! command -v ruby &> /dev/null; then
    echo "Installing Ruby and dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y ruby-full ruby-bundler build-essential libsqlite3-dev
fi

# Check if bundler is up to date
if \! gem list bundler -i &> /dev/null; then
    echo "Installing bundler gem..."
    sudo gem install bundler
fi

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

# Setup ImageMagick symlinks if needed
for cmd in identify mogrify convert; do
    if \! command -v $cmd &> /dev/null; then
        BINARY=$(ls /usr/bin/${cmd}-* 2>/dev/null | grep -E "${cmd}-im[0-9]" | head -1)
        if [ -n "$BINARY" ]; then
            sudo ln -sf "$BINARY" "/usr/local/bin/$cmd" 2>/dev/null || true
        fi
    fi
done

# Mark setup as complete
touch .terragon-setup-complete

echo "Rails setup complete\!"
