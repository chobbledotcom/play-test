# play-test - Inflatable Play Equipment Inspection Tool

A web app for managing safety inspections of inflatable play equipment like bouncy castles and slides. Built by [Chobble.com](https://chobble.com).

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Docker Image](https://img.shields.io/badge/docker-dockerstefn%2Fplay--test-blue)](https://hub.docker.com/r/dockerstefn/play-test)

## What's This?

play-test helps inspectors track and document safety checks on inflatable play equipment. It handles equipment records, inspection forms, photo management, and PDF report generation. Makes repeat inspections of the same units quick and straightforward.

Currently in alpha testing at [play-test.co.uk](https://play-test.co.uk).

## Key Features

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

We've got a Nix flake for easy environment setup:

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

We maintain over 97% test coverage:

```bash
# Run all tests with coverage
bin/test

# Check specific file coverage
ruby coverage_check.rb app/models/inspection.rb

# View detailed HTML report
open coverage/index.html
```

## Tech Stack

- **Rails 8.0+** - Keeping it simple with minimal gems
- **SQLite** - Simple, reliable database
- **RSpec & Capybara** - Comprehensive test suite
- **Semantic HTML + MVP.css** - No CSS framework bloat
- **Turbo** - Snappy interactions without the JavaScript complexity

## Contributing

Pull requests welcome! This is an open source project (AGPLv3) and we're not affiliated with any industry bodies, so improvements from anyone are appreciated.

Before contributing:
1. Check out `CLAUDE.md` for coding standards
2. Run the tests
3. Follow British English conventions
4. Keep the minimal dependency philosophy

## Design Philosophy

- **Open and Independent**: Not tied to any regulatory body or industry group
- **Practical Focus**: Built for real inspectors doing real work
- **Privacy First**: Your data stays yours
- **Simple but Complete**: Everything you need, nothing you don't

## License

AGPLv3 - see [LICENSE](LICENSE) file. This means you can use, modify, and distribute the code, but you must share any improvements.

## About

Built by [Chobble.com](https://chobble.com), a Manchester-based web development shop. We build practical tools that solve real problems.

---

*Note: This is alpha software. While it's being used for real inspections, expect rough edges and ongoing improvements.*