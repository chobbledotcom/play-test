#!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script - OPTIMIZED FOR SPEED
# Runs once per new environment - optimized for first-run performance

echo "Setting up Terragon Rails environment..."

# Run apt-get update and install in one command (faster)
echo "Installing system packages..."
DEBIAN_FRONTEND=noninteractive sudo apt-get update -qq && \
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y -qq \
    ruby-full ruby-bundler build-essential libsqlite3-dev \
    libyaml-dev libvips-dev cmake pkg-config sassc \
    --no-install-recommends

# Install bundler with no documentation (faster)
echo "Installing bundler..."
sudo gem install bundler --no-document --quiet

# Install gems with maximum parallelization
echo "Installing gems (parallel)..."
bundle install --jobs $(nproc) --retry 2 --quiet

# Create both databases in parallel (big time saver)
echo "Setting up databases in parallel..."

# Start both database setups in background
(
    echo "  Creating development database..."
    bundle exec rails db:create db:migrate db:seed --trace 2>/dev/null
) &
DEV_PID=$!

(
    echo "  Creating test database..."
    RAILS_ENV=test bundle exec rails db:create db:migrate --trace 2>/dev/null
    bundle exec rails parallel:prepare 2>/dev/null
) &
TEST_PID=$!

# Wait for both to complete
wait $DEV_PID && echo "  ✓ Development database ready"
wait $TEST_PID && echo "  ✓ Test database ready"

echo "✓ Rails setup complete!"