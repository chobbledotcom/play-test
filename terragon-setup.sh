#!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script - Extract from Docker Version
# Extracts Ruby/gems from Docker image without running containers

# Skip if already set up (optimization for repeated runs)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    echo "Setup already complete. Run with FORCE_SETUP=1 to re-run."
    exit 0
fi

echo "Pulling production Docker image..."
docker pull git.chobble.com/chobble/play-test:latest

echo "Extracting Ruby and gems from Docker image..."
# Create a temporary container (not running)
container_id=$(docker create git.chobble.com/chobble/play-test:latest)

# Extract the bundle directory and Ruby installation
echo "Copying bundle and Ruby files..."
docker cp $container_id:/usr/local/bundle /tmp/bundle.tar
sudo tar -xf /tmp/bundle.tar -C /usr/local/
rm /tmp/bundle.tar

# Extract Ruby if needed (the image uses ruby:3.4.3-slim as base)
docker cp $container_id:/usr/local/lib/ruby /tmp/ruby.tar
sudo tar -xf /tmp/ruby.tar -C /usr/local/lib/
rm /tmp/ruby.tar

docker cp $container_id:/usr/local/bin/ruby /tmp/ruby-bin.tar
sudo tar -xf /tmp/ruby-bin.tar -C /usr/local/bin/
rm /tmp/ruby-bin.tar

# Clean up container
docker rm $container_id

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
