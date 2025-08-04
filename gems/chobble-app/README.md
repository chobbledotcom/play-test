# ChobbleApp

Core infrastructure gem for Chobble applications. Provides user management, authentication, and shared functionality.

## Features

- User authentication and session management
- User management (CRUD operations)
- Event logging system
- Static page CMS functionality
- Shared views and partials
- Base controllers and models
- Theme support (light/dark/minimal)
- Image processing helpers
- Turbo Stream responders
- Infrastructure templates (Docker, linters, CI/CD)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chobble_app', path: 'gems/chobble-app'
```

And then execute:

    $ bundle install

## Usage

### Models

Your app models should inherit from the gem's base classes:

```ruby
class ApplicationRecord < ChobbleApp::ApplicationRecord
  self.abstract_class = true
end

class User < ChobbleApp::User
  # Add app-specific associations and methods
  has_many :inspections
end

class Event < ChobbleApp::Event
  # App-specific customizations
end

class Page < ChobbleApp::Page
  # App-specific customizations
end
```

### Controllers

Your controllers should inherit from the gem's base controllers:

```ruby
class ApplicationController < ChobbleApp::ApplicationController
  # Add app-specific concerns
  include ImageProcessable
end

class SessionsController < ChobbleApp::SessionsController
  private

  def after_login_path
    inspections_path # Override the default
  end
end

class UsersController < ChobbleApp::UsersController
  # Override hooks for app-specific behavior
  private

  def load_app_specific_data
    @inspection_counts = Inspection.group(:user_id).count
  end
end
```

### Helpers

Include the gem's helpers in your app:

```ruby
module ApplicationHelper
  include ChobbleApp::ApplicationHelper
  # Add app-specific helpers
end

module SessionsHelper
  include ChobbleApp::SessionsHelper
end

module UsersHelper
  include ChobbleApp::UsersHelper
  
  # Add app-specific helpers
  def inspection_count(user)
    user.inspections.count
  end
end
```

### Routes

The gem doesn't provide routes - define them in your main application as needed.

### Infrastructure Setup

The gem includes standard infrastructure files that can be copied to your app:

    $ bundle exec rake chobble_app:setup_infrastructure

This will copy:
- Dockerfile and .dockerignore
- Linter configurations (.rubocop.yml, .standard.yml, .erb_lint.yml, .better-html.yml)
- GitHub workflow files (CI, security scanning, etc.)
- Development tools (bin/lint, bin/test, bin/rspec-find, etc.)

You can also run the setup script directly:

    $ ruby gems/chobble-app/infrastructure/setup_infrastructure.rb [target_directory]

## Testing

The gem includes comprehensive specs for the core infrastructure. To run tests:

    $ cd gems/chobble-app
    $ bundle install
    $ bundle exec rspec

The gem includes:
- Model specs for User, Event, and Page
- Controller specs for ApplicationController
- Helper specs for sessions and users
- Request specs for authentication and user management
- View specs for user interfaces
- Feature specs for UI functionality

When using the gem in your app, you can extend the factories:

```ruby
# spec/factories/users_app.rb
FactoryBot.modify do
  factory :user do
    association :inspection_company # Add app-specific associations
  end
end
```

## Development

When developing the gem, ensure all specs pass before releasing.

## Contributing

Bug reports and pull requests are welcome.