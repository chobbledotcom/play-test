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

# Skopeo stores layers as individual files, not tars
# Extract all layers (they're already uncompressed)
for layer in *; do
    if [ -f "$layer" ]; then
        echo "Checking layer: $layer"
        # Try to extract as tar, handling both compressed and uncompressed
        if file "$layer" | grep -q "gzip"; then
            if zcat "$layer" | tar -t 2>/dev/null | grep -q "usr/local/bundle\|usr/local/lib/ruby\|usr/local/bin/ruby"; then
                echo "Extracting from compressed layer: $layer"
                sudo zcat "$layer" | tar -x -C / 2>/dev/null || true
            fi
        else
            if tar -tf "$layer" 2>/dev/null | grep -q "usr/local/bundle\|usr/local/lib/ruby\|usr/local/bin/ruby"; then
                echo "Extracting from layer: $layer"
                sudo tar -xf "$layer" -C / 2>/dev/null || true
            fi
        fi
    fi
done

cd -
rm -rf /tmp/play-test-image

# Set up environment
export GEM_HOME=/usr/local/bundle
export PATH=$GEM_HOME/bin:$PATH
echo "export GEM_HOME=/usr/local/bundle" >> ~/.bashrc
echo "export PATH=\$GEM_HOME/bin:\$PATH" >> ~/.bashrc

# Database setup
echo "Setting up databases..."
bundle exec rails db:create db:migrate db:seed
RAILS_ENV=test bundle exec rails db:create db:migrate

# Mark setup as complete
touch .terragon-setup-complete

echo "Rails setup complete!"
echo "You can now run Rails commands directly:"
echo "  rails s"
echo "  rails c"
echo "  bundle exec rspec"