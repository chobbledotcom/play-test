#!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script - OPTIMIZED VERSION
# Runs on every sandbox start - now much faster!

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a package is installed
package_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

# Function to check if gem is installed
gem_installed() {
    gem list -i "$1" >/dev/null 2>&1
}

# Skip if Gemfile.lock hasn't changed (most common scenario)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    if [ -f ".terragon-gemfile-checksum" ] && [ -f "Gemfile.lock" ]; then
        current_checksum=$(sha256sum Gemfile.lock | cut -d' ' -f1)
        stored_checksum=$(cat .terragon-gemfile-checksum 2>/dev/null || echo "")
        
        if [ "$current_checksum" = "$stored_checksum" ]; then
            echo -e "${GREEN}✓ Setup already complete and gems unchanged${NC}"
            
            # Quick database check (very fast)
            if [ ! -f "storage/development.sqlite3" ] || [ ! -f "storage/test.sqlite3" ]; then
                echo -e "${YELLOW}⚠ Databases missing, recreating...${NC}"
            else
                echo -e "${GREEN}✓ All databases present${NC}"
                exit 0
            fi
        else
            echo -e "${YELLOW}⚠ Gemfile.lock changed, updating gems...${NC}"
        fi
    fi
fi

echo -e "${YELLOW}Starting Terragon Rails setup...${NC}"

# Check and install system packages (only if needed)
PACKAGES_TO_INSTALL=""
REQUIRED_PACKAGES="ruby-full ruby-bundler build-essential libsqlite3-dev libyaml-dev libvips-dev cmake pkg-config"

for package in $REQUIRED_PACKAGES; do
    if ! package_installed "$package"; then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $package"
    fi
done

if [ -n "$PACKAGES_TO_INSTALL" ]; then
    echo -e "${YELLOW}Installing missing packages:$PACKAGES_TO_INSTALL${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq $PACKAGES_TO_INSTALL
else
    echo -e "${GREEN}✓ All system packages already installed${NC}"
fi

# Check bundler (much faster than always installing)
if ! gem_installed "bundler"; then
    echo -e "${YELLOW}Installing bundler gem...${NC}"
    sudo gem install bundler --no-document
else
    echo -e "${GREEN}✓ Bundler already installed${NC}"
fi

# Optimize bundle install with better caching
echo -e "${YELLOW}Checking gems...${NC}"

# Use bundle check first (very fast)
if bundle check >/dev/null 2>&1; then
    echo -e "${GREEN}✓ All gems already installed and satisfied${NC}"
else
    echo -e "${YELLOW}Installing/updating gems...${NC}"
    # Use more aggressive parallelization and skip documentation
    bundle install --jobs $(nproc) --retry 3 --quiet
fi

# Store Gemfile.lock checksum for next run
if [ -f "Gemfile.lock" ]; then
    sha256sum Gemfile.lock | cut -d' ' -f1 > .terragon-gemfile-checksum
fi

# Parallel database setup (run both at once)
DB_SETUP_NEEDED=false

if [ ! -f "storage/development.sqlite3" ] || [ ! -f "storage/test.sqlite3" ]; then
    DB_SETUP_NEEDED=true
    echo -e "${YELLOW}Setting up databases in parallel...${NC}"
    
    # Run database setups in parallel
    (
        if [ ! -f "storage/development.sqlite3" ]; then
            echo "Creating development database..."
            bundle exec rails db:create db:migrate db:seed
            echo -e "${GREEN}✓ Development database ready${NC}"
        fi
    ) &
    DEV_PID=$!
    
    (
        if [ ! -f "storage/test.sqlite3" ]; then
            echo "Creating test database..."
            RAILS_ENV=test bundle exec rails db:create db:migrate
            bundle exec rails parallel:prepare
            echo -e "${GREEN}✓ Test database ready${NC}"
        fi
    ) &
    TEST_PID=$!
    
    # Wait for both to complete
    wait $DEV_PID
    wait $TEST_PID
else
    echo -e "${GREEN}✓ All databases already exist${NC}"
fi

# Mark setup as complete
touch .terragon-setup-complete

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Terragon Rails setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"