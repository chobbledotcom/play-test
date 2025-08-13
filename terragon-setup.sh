#!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script - Skopeo Version
# Uses skopeo to download Docker image without Docker daemon

# Skip if already set up (optimization for repeated runs)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    echo "Setup already complete. Run with FORCE_SETUP=1 to re-run."
    exit 0
fi

echo "Installing skopeo..."
sudo apt-get update
sudo apt install -y skopeo

echo "Downloading Docker image with skopeo..."
skopeo copy docker://git.chobble.com/chobble/play-test:latest dir:/tmp/play-test-image

echo "Extracting Ruby and gems from image layers..."
cd /tmp/play-test-image

# Create a safe extraction directory
mkdir -p /tmp/docker-extract

# Extract layers to a temporary location first
for layer in *; do
    if [ -f "$layer" ] && [ "$layer" != "manifest.json" ] && [ "$layer" != "version" ]; then
        echo "Processing layer: $layer"
        # Extract to temp location
        tar -xf "$layer" -C /tmp/docker-extract 2>/dev/null || true
    fi
done

# Now selectively copy only Ruby and bundle files
echo "Copying Ruby and bundle files..."
if [ -d "/tmp/docker-extract/usr/local/bin" ]; then
    sudo cp -a /tmp/docker-extract/usr/local/bin/ruby /usr/local/bin/ 2>/dev/null || true
    sudo cp -a /tmp/docker-extract/usr/local/bin/gem /usr/local/bin/ 2>/dev/null || true
    sudo cp -a /tmp/docker-extract/usr/local/bin/bundle /usr/local/bin/ 2>/dev/null || true
    sudo cp -a /tmp/docker-extract/usr/local/bin/bundler /usr/local/bin/ 2>/dev/null || true
fi

if [ -d "/tmp/docker-extract/usr/local/lib/ruby" ]; then
    sudo cp -ar /tmp/docker-extract/usr/local/lib/ruby /usr/local/lib/ 2>/dev/null || true
fi

# Copy all libraries but don't overwrite existing ones
echo "Copying libraries (without overwriting)..."
if [ -d "/tmp/docker-extract/usr/local/lib" ]; then
    sudo cp -rn /tmp/docker-extract/usr/local/lib/* /usr/local/lib/ 2>/dev/null || true
fi

if [ -d "/tmp/docker-extract/usr/lib/x86_64-linux-gnu" ]; then
    sudo cp -rn /tmp/docker-extract/usr/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true
fi

# Update shared library cache
sudo ldconfig

if [ -d "/tmp/docker-extract/usr/local/include/ruby-3.4.0" ]; then
    sudo cp -ar /tmp/docker-extract/usr/local/include/ruby-3.4.0 /usr/local/include/ 2>/dev/null || true
fi

if [ -d "/tmp/docker-extract/usr/local/bundle" ]; then
    sudo cp -ar /tmp/docker-extract/usr/local/bundle /usr/local/ 2>/dev/null || true
fi

# Copy Rails app files if they exist
if [ -d "/tmp/docker-extract/rails" ]; then
    cp -ar /tmp/docker-extract/rails/* . 2>/dev/null || true
fi

# Clean up
cd -
rm -rf /tmp/play-test-image
rm -rf /tmp/docker-extract

# Ruby and bundle are now in /usr/local/bin
echo "Verifying Ruby installation..."
ls -la /usr/local/bin/ruby || echo "Ruby binary not found"
ls -la /usr/local/bin/bundle || echo "Bundle binary not found"
/usr/local/bin/ruby --version || echo "Ruby not working"
/usr/local/bin/bundle --version || echo "Bundle not working"

# Set up environment - include /usr/local/bin in PATH
export GEM_HOME=/usr/local/bundle
export BUNDLE_PATH=/usr/local/bundle
# Include the versioned Ruby bin directory where Rails lives
export PATH=/usr/local/bin:$GEM_HOME/bin:$GEM_HOME/ruby/3.4.0/bin:$PATH

echo "export GEM_HOME=/usr/local/bundle" >> ~/.bashrc
echo "export BUNDLE_PATH=/usr/local/bundle" >> ~/.bashrc
echo "export PATH=/usr/local/bin:\$GEM_HOME/bin:\$GEM_HOME/ruby/3.4.0/bin:\$PATH" >> ~/.bashrc

# Check if Rails is accessible
echo "Checking for Rails..."
ls -la $GEM_HOME/ruby/3.4.0/bin/rails 2>/dev/null || echo "Rails not found in expected location"

# Configure bundler to skip development, test, and CI groups (production image doesn't have them)
echo "Configuring bundler..."
/usr/local/bin/bundle config set --local without 'development test ci_annotations ci_coverage'
/usr/local/bin/bundle config set --local deployment false

# Install any missing production gems
echo "Installing production gems..."
/usr/local/bin/bundle install --jobs 4

# Generate a secret key for production
echo "Generating secret key..."
SECRET_KEY_BASE=$(/usr/local/bin/bundle exec rails secret)

# Database setup in production mode (since we don't have dev/test gems)
echo "Setting up databases..."
RAILS_ENV=production SECRET_KEY_BASE=$SECRET_KEY_BASE /usr/local/bin/bundle exec rails db:create db:migrate db:seed

# Save the secret key for future use
echo "export SECRET_KEY_BASE=$SECRET_KEY_BASE" >> ~/.bashrc

# Mark setup as complete
touch .terragon-setup-complete

echo "Rails setup complete!"
echo "You can now run Rails commands directly:"
echo "  rails s"
echo "  rails c"
echo "  bundle exec rspec"
