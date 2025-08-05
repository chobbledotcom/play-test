# play-test - BS EN 14960 inspection-logging tool

A web app for managing safety inspections of inflatable play equipment like bouncy castles and slides. Built by [Chobble.com](https://chobble.com).

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Docker Image](https://img.shields.io/badge/docker-dockerstefn%2Fplay--test-blue)](https://hub.docker.com/r/dockerstefn/play-test)
[![codecov](https://codecov.io/gh/chobbledotcom/play-test/branch/main/graph/badge.svg?token=6NY2ZHY4R8)](https://codecov.io/gh/chobbledotcom/play-test)

play-test helps inspectors track and document safety checks on inflatable play equipment. It handles equipment records, inspection forms, photo management, and PDF report generation. Makes repeat inspections of the same units quick and straightforward.

A public instance is live at **[play-test.co.uk](https://play-test.co.uk)**.

## Sponsor Development

- [**OpenCollective**.com/play-test](https://opencollective.com/play-test)
- [**LiberaPay**.com/chobble](https://liberapay.com/chobble/)
- [**Patreon**.com/chobble](https://www.patreon.com/c/Chobble)

## Features

### 🎪 Equipment Tracking

- Store unit details, dimensions, and manufacturer info
- Keep inspection history for each piece of equipment
- Upload photos with automatic processing
- Quick access to previous inspection data

### 📋 Inspection Management

- Seven assessment types covering different safety aspects
- Draft inspections you can edit before finalising
- Generate PDF reports with QR codes
- Built-in safety calculations (anchor points, user capacity, etc.)

### 👥 Company Management

- Company accounts with branding
- User management and access control
- Upload your logo for PDF reports
- Works on phones, tablets, and desktops

### 🛠️ Technical Features

- Export any unit or inspection as PDF or JSON
- Shows safety standards right where you need them
- Dark/light theme
- Minimal dependencies
- Full internationalisation support
- No JavaScript required for core functionality

## Getting Started

### Docker

Quickest way to try it out:

```bash
docker pull dockerstefn/play-test
docker run -p 3000:3000 dockerstefn/play-test
```

### Development Setup

There's a Nix flake for easy environment setup:

```bash
# Clone the repo
git clone https://github.com/yourusername/play-test.git
cd play-test

# With direnv (recommended)
direnv allow

# Or manually with Nix
nix develop

# Standard Rails setup
bundle install
rails db:create db:migrate db:seed
rails server
```

### Traditional Setup

```bash
# Requires Ruby 3.0+ and SQLite
bundle install
rails db:setup
rails server
```

## Testing

Currently over 90% test coverage:

```bash
# Run all tests with coverage
bin/test

# Check specific file coverage
bin/coverage_check app/models/inspection.rb

# View detailed HTML report
open coverage/index.html
```

## Test Coverage

If you want to help improve Play-Test, a great way would be to write some more `rspec` and `Capybara` tests. Check out [coverage.play-test.co.uk](https://coverage.play-test.co.uk/) for an up-to-date test coverage breakdown.

## Tech Stack

- **Rails 8.0+** - With minimal gems
- **SQLite** - No fancy databases (yet?)
- **RSpec & Capybara** - 90%+ test coverage
- **Semantic HTML + MVP.css** - Simple CSS
- **Turbo** for progressive JS enhancement

## Contributing

Pull requests welcome! This is an open source project and we're not affiliated with any industry bodies, so improvements from anyone are appreciated.

AGPLv3 - see [LICENSE](LICENSE) file. This means you can use, modify, and distribute the code, but you must share any improvements.

Built by [Chobble](https://chobble.com) - an ethical and open source web and software developer in Prestwich, Manchester, UK
