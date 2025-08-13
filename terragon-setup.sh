#!/bin/bash
set -euo pipefail

# Terragon Labs Rails Setup Script - Docker Version
# Uses pre-built Docker image instead of apt installs

# Skip if already set up (optimization for repeated runs)
if [ -f ".terragon-setup-complete" ] && [ -z "${FORCE_SETUP:-}" ]; then
    echo "Setup already complete. Run with FORCE_SETUP=1 to re-run."
    exit 0
fi

echo "Pulling production Docker image..."
docker pull git.chobble.com/chobble/play-test:latest

# Database setup using Docker
echo "Setting up databases..."
docker run --rm -v "$PWD:/app" -w /app -e RAILS_ENV=development \
  git.chobble.com/chobble/play-test:latest \
  bash -c "rails db:create db:migrate db:seed && RAILS_ENV=test rails db:create db:migrate"

# Create universal helper script
echo '#!/bin/bash
docker run -it --rm -p 3000:3000 -v "$PWD:/app" -w /app -e RAILS_ENV=development \
  git.chobble.com/chobble/play-test:latest "$@"' > dr
chmod +x dr

# Mark setup as complete
touch .terragon-setup-complete

echo "Rails setup complete!"
echo "Use ./dr to run any Rails command:"
echo "  ./dr rails s -b 0.0.0.0   # Start server"
echo "  ./dr rails c               # Console"
echo "  ./dr bash                  # Shell"