# patlog - A PAT Inspection Logger

A Ruby on Rails application for managing Portable Appliance Testing (PAT) inspections and generating certificates with QR codes for verification.

**[patlog.co.uk](https://patlog.co.uk)**

## Requirements

* Ruby 3.2+
* Rails 7.2+
* SQLite 3

## Setup

### Docker Installation

The easiest way to install PAT Logger is using Docker:

```
docker pull dockerstefn/patlog
docker run -p 3000:3000 dockerstefn/patlog
```

Visit http://localhost:3000 in your browser.

### Manual Installation

1. Clone the repository
2. Install dependencies:
   ```
   bundle install
   ```
3. Create the database:
   ```
   rails db:create db:migrate
   ```
4. Configure environment variables:
   ```
   cp .env.example .env
   ```
   Then edit `.env` and set your application's base URL (e.g., `https://yourdomain.com` or `http://localhost:3000` for development).

   Available environment variables:
   - `BASE_URL`: The base URL for your application (required)
   - `LIMIT_INSPECTIONS`: Default number of inspections allowed per user (default: 10, set to -1 for unlimited)

5. Start the Rails server:
   ```
   rails server
   ```

## Features

* PAT inspection records management
* PDF certificate generation
* QR code generation for certificate verification
* User authentication and authorization
* Search functionality for inspections
* Image attachment for equipment photos

## Testing

Run the test suite with:
```
rspec
```
