# Sorbet Type Checking

This directory contains Sorbet configuration for gradual static typing in this Rails application.

## Setup

Sorbet is already configured in this project. The generated RBI files are gitignored and should be regenerated locally.

## Generating RBI Files

When you first clone the repository or when gems change, generate the RBI files:

```bash
# Generate RBI files for all gems
bundle exec tapioca gem --all

# Generate RBI files for Rails DSL methods
bundle exec tapioca dsl
```

## Type Checking

Run Sorbet to check types:

```bash
# Type check all files
bundle exec srb tc

# Type check a specific file
bundle exec srb tc app/models/page.rb
```

## Adding Type Annotations

1. Add `# typed: true` to the top of the file
2. Add `extend T::Sig` to classes that need method signatures
3. Add `sig` blocks above methods to specify types

Example:
```ruby
# typed: true
class MyModel < ApplicationRecord
  extend T::Sig

  sig { returns(String) }
  def my_method
    "hello"
  end
end
```

## Strictness Levels

- `# typed: ignore` - Skip type checking
- `# typed: false` - Minimal checking (default)
- `# typed: true` - Standard checking
- `# typed: strict` - Strict checking
- `# typed: strong` - Strictest checking

## Configuration

- `sorbet/config` - Sorbet configuration
- `sorbet/tapioca/config.yml` - Tapioca configuration
- `sorbet/rbi/` - Generated type definitions (gitignored)

## More Information

- [Sorbet Documentation](https://sorbet.org/)
- [Tapioca Documentation](https://github.com/Shopify/tapioca)