#!/bin/bash
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
if ! command -v ruby &> /dev/null; then
    echo "Ruby not found. Installing Ruby 3.4.3..."
    
    # Install Ruby dependencies
    sudo apt-get update -qq
    sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev \
        libsqlite3-dev libyaml-dev libffi-dev
    
    # Install rbenv and ruby-build
    if ! command -v rbenv &> /dev/null; then
        git clone https://github.com/rbenv/rbenv.git ~/.rbenv
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(rbenv init -)"' >> ~/.bashrc
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
        
        # Install ruby-build plugin
        git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    fi
    
    # Install Ruby 3.4.3
    rbenv install 3.4.3
    rbenv global 3.4.3
    eval "$(rbenv init -)"
fi

# Check if bundler is installed
if ! gem list bundler -i &> /dev/null; then
    echo "Installing bundler..."
    gem install bundler
fi

# Install Rails dependencies with bundler
echo "Installing gems..."
bundle install --jobs 4

# Database setup (only if not exists)
if [ ! -f "storage/development.sqlite3" ]; then
    echo "Creating development database..."
    bundle exec rails db:create db:migrate db:seed
fi

# Test database setup (only if not exists)
if [ ! -f "storage/test.sqlite3" ]; then
    echo "Creating test database..."
    RAILS_ENV=test bundle exec rails db:create db:migrate
    bundle exec rails parallel:prepare
fi

# Setup ImageMagick symlinks if needed
for cmd in identify mogrify convert; do
    if ! command -v $cmd &> /dev/null; then
        BINARY=$(ls /usr/bin/${cmd}-* 2>/dev/null | grep -E "${cmd}-im[0-9]" | head -1)
        if [ -n "$BINARY" ]; then
            sudo ln -sf "$BINARY" "/usr/local/bin/$cmd" 2>/dev/null || true
        fi
    fi
done

# Mark setup as complete
touch .terragon-setup-complete

echo "Rails setup complete!"