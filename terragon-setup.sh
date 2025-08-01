#!/bin/bash
set -euo pipefail

# Terragon Labs Rails Application Setup Script
# This script installs all necessary dependencies to run the Rails application

echo "================================"
echo "Terragon Labs Rails Setup Script"
echo "================================"
echo

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    DISTRO=$(lsb_release -si 2>/dev/null || echo "unknown")
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    echo "Error: Unsupported operating system: $OSTYPE"
    exit 1
fi

echo "Detected OS: $OS"
[[ "$OS" == "linux" ]] && echo "Detected Distribution: $DISTRO"
echo

# Ruby version from .ruby-version file
RUBY_VERSION=$(cat .ruby-version | tr -d '\n' | sed 's/ruby-//')
echo "Ruby version required: $RUBY_VERSION"
echo

# Function to install packages on Ubuntu/Debian
install_apt_packages() {
    echo "Updating package list..."
    sudo apt-get update -qq

    echo "Installing system dependencies..."
    sudo apt-get install -y \
        curl \
        git \
        build-essential \
        pkg-config \
        libjemalloc2 \
        sqlite3 \
        libsqlite3-dev \
        libvips42 \
        imagemagick \
        libmagickwand-dev \
        libyaml-dev \
        libssl-dev \
        libreadline-dev \
        zlib1g-dev \
        libncurses5-dev \
        libffi-dev \
        libgdbm-dev \
        google-chrome-stable || true  # Chrome might not be available in all repos
}

# Function to install packages on macOS
install_brew_packages() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Installing system dependencies via Homebrew..."
    brew install \
        sqlite3 \
        vips \
        imagemagick \
        libyaml \
        openssl \
        readline \
        rbenv \
        ruby-build
}

# Install system packages based on OS
if [[ "$OS" == "linux" ]]; then
    install_apt_packages
elif [[ "$OS" == "macos" ]]; then
    install_brew_packages
fi

# Install Ruby using rbenv
echo
echo "Setting up Ruby $RUBY_VERSION..."

if [[ "$OS" == "linux" ]]; then
    # Install rbenv for Linux if not present
    if ! command -v rbenv &> /dev/null; then
        echo "Installing rbenv..."
        git clone https://github.com/rbenv/rbenv.git ~/.rbenv
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
        echo 'eval "$(rbenv init -)"' >> ~/.bashrc
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init -)"
        
        # Install ruby-build
        git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    fi
fi

# Ensure rbenv is in PATH for current session
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init -)"
fi

# Install Ruby version if not already installed
if ! rbenv versions | grep -q "$RUBY_VERSION"; then
    echo "Installing Ruby $RUBY_VERSION..."
    rbenv install $RUBY_VERSION
else
    echo "Ruby $RUBY_VERSION is already installed"
fi

# Set the Ruby version for this project
rbenv local $RUBY_VERSION

# Install Bundler
echo
echo "Installing Bundler..."
gem install bundler

# Install Rails dependencies
echo
echo "Installing Rails dependencies..."
bundle install

# Setup ImageMagick symlinks on Linux (if needed)
if [[ "$OS" == "linux" ]]; then
    echo
    echo "Setting up ImageMagick symlinks..."
    for cmd in identify mogrify convert; do
        if ! command -v $cmd &> /dev/null; then
            BINARY=$(ls /usr/bin/${cmd}-* 2>/dev/null | grep -E "${cmd}-im[0-9]" | head -1)
            if [ -n "$BINARY" ]; then
                echo "Creating symlink: $BINARY -> /usr/local/bin/$cmd"
                sudo ln -sf "$BINARY" "/usr/local/bin/$cmd"
            else
                echo "Warning: No binary found for $cmd"
            fi
        fi
    done
fi

# Database setup
echo
echo "Setting up database..."
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

# Test database setup
echo
echo "Setting up test database..."
RAILS_ENV=test bundle exec rails db:create
RAILS_ENV=test bundle exec rails db:migrate

# Parallel test database setup
echo
echo "Preparing parallel test databases..."
bundle exec rails parallel:prepare

# Precompile assets (optional for development)
echo
echo "Precompiling assets..."
bundle exec rails assets:precompile

echo
echo "================================"
echo "Setup Complete!"
echo "================================"
echo
echo "You can now run the Rails server with:"
echo "  rails s"
echo
echo "Or run tests with:"
echo "  bin/test"
echo
echo "For more commands, check CLAUDE.md"