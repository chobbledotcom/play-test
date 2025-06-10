# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands

- Run server: `rails s` or `bundle exec rails server`
- Rails console: `rails c`
- **Lint modified files only**: `bundle exec standardrb --fix path/to/file.rb` (NEVER run on entire repo)
- Lint check (no fix): `bundle exec standardrb path/to/file.rb`
- **ERB files don't need linting with standardrb**
- **Run tests (parallel)**: `bin/test` (RECOMMENDED - clean output with coverage summary)
- Run all tests: `bundle exec rspec` (WARNING: Takes ages - only run when specifically requested)  
- **Run tests in parallel**: `bundle exec parallel_rspec spec/` (verbose output)
- **Run parallel tests with coverage**: `bundle exec rake coverage:parallel`
- Run single test: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- Run with verbose output: `bundle exec rspec --format documentation`
- Prepare parallel test databases: `bundle exec rails parallel:prepare`

## Environment Notes

- **ripgrep (rg) is NOT installed** - use `grep` command instead of `rg` for searching
- **Full test suite is SLOW** - only run `bundle exec rspec` when explicitly requested
- Prefer running individual test files or specific tests during development
- **Database locking**: If tests fail with "database is locked", just inform the user and wait for them to confirm it's unlocked
- **NEVER paste code into Rails console** - it never works. Instead write very specific RSpec tests

## Core Development Principles

### Internationalization (i18n) - ALWAYS
- **EVERY string must use I18n** - no hardcoded text anywhere
- **Split locale files** - create new files in `config/locales/` instead of growing `en.yml`
- Organize keys logically: `users.messages.company_archived`
- Use I18n in tests: `I18n.t("inspector_companies.buttons.archive")`
- Structure: `controller.section.key` or `model.field.description`

### Testing Approach
- **Write Capybara tests for ALL new code** - no exceptions
- **No JavaScript in tests** - test the non-JS fallback behavior
- **Run tests immediately** - write test, run it, fix issues before moving on
- Use **RSpec** with descriptive contexts/examples
- Use **Factory Bot** for test data creation
- Test both happy path and edge cases
- Use `--fail-fast` during development to fix issues incrementally

### Code Organization
- **Create partials for repeated code** - DRY principle
- Extract common view code into partials immediately
- Use semantic naming for partials: `_user_details.html.erb`
- Keep partials focused on a single responsibility

### HTML & CSS Philosophy
- **Semantic HTML only** - use proper tags for their intended purpose
- **ABSOLUTELY NO CSS classes** - I hate CSS classes, never use them
- **NO class attributes at all** - rely entirely on semantic selectors
- **NO inline styles** - add CSS to dedicated CSS files using semantic selectors
- Use MVP.css framework's semantic styling only
- Structure: `<article>`, `<header>`, `<nav>`, `<main>` (avoid `<section>`)
- Forms: `<fieldset>`, `<legend>`, proper `<label>` associations
- Tables: `<thead>`, `<tbody>`, `<th>` with proper scope
- Buttons: use `<button>` or `<input type="submit">` without any classes

### Code Quality Standards
- **No defensive coding** - expect correct data, let it fail if wrong
- **No fallbacks** - if data is missing, that's an error to fix
- **Update old code** - don't support legacy patterns, refactor to new standards
- Fix the root cause, not the symptom
- Explicit is better than implicit

### Development Philosophy & Architecture

### Frontend & UI Principles
- **Progressive enhancement** - HTML first, enhance with Turbo
- **Turbo-first** - use Turbo for form submissions and navigation
  - Use `data: { turbo_method: :patch }` instead of old Rails UJS
  - Use `data: { turbo_confirm: "message" }` for confirmations
  - Auto-submit forms with `onchange: "this.form.submit();"`
- **Accessibility** - proper labels, ARIA where needed, keyboard navigation

### Database & Models
- Use descriptive field names: `inspection_location` not `location`
- Write validations for data integrity
- Use scopes for complex queries: `InspectorCompany.by_status("active")`
- Make private helper methods for cleaner public interfaces
- Always validate associations and required fields

### Controllers & Business Logic
- Keep controllers thin - delegate to models/services
- Use semantic parameter names: "active", "archived", "all" not true/false strings
- Use proper HTTP methods (PATCH for updates, not GET)
- Let errors bubble up - don't rescue unless you can handle it properly
- Use Rails conventions - don't reinvent the wheel

### Code Style Guidelines

- Uses Standard Ruby for formatting (standardrb)
- Models: singular, CamelCase (User)
- Controllers: plural, CamelCase (UsersController)
- Files/methods/variables: snake_case
- Constants: SCREAMING_SNAKE_CASE
- Service objects for complex business logic
- ActiveRecord validations for data integrity
- Error handling with begin/rescue with specific error messages
- Flash messages for user-facing errors

## Established Patterns & Examples

### Testing Patterns
```ruby
# Feature tests with Capybara
RSpec.feature "Inspector Company Archiving", type: :feature do
  let(:admin_user) { create(:user, :without_company, email: "admin@testcompany.com") }
  
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ADMIN_EMAILS_PATTERN").and_return("admin@")
    sign_in(admin_user)
  end

  it "archives a company when clicking the archive link" do
    visit inspector_companies_path
    click_link I18n.t("inspector_companies.buttons.archive")
    expect(page).to have_content(I18n.t("inspector_companies.messages.archived"))
  end
end

# Model scopes for clean queries
scope :by_status, ->(status) {
  case status&.to_s
  when "active" then active
  when "archived" then archived  
  when "all" then all
  else all # Default to all
  end
}
```

### Turbo Form Patterns
```erb
<!-- Auto-submit dropdown -->
<%= form_with url: inspector_companies_path, method: :get, data: { turbo: false } do |form| %>
  <%= form.select :active, 
      options_for_select([
        ["All Companies", "all"],
        [t('inspector_companies.status.active'), "active"],
        [t('inspector_companies.status.archived'), "archived"]
      ], params[:active]),
      {}, { onchange: "this.form.submit();" } %>
<% end %>

<!-- Action links with Turbo -->
<%= link_to t('inspector_companies.buttons.archive'), 
      archive_inspector_company_path(company), 
      data: { 
        turbo_method: :patch, 
        turbo_confirm: "Are you sure you want to archive #{company.name}?" 
      } %>
```

### Controller Patterns
```ruby
# Clean, chainable scopes
def index
  @inspector_companies = InspectorCompany
    .by_status(params[:active])
    .search_by_term(params[:search])
    .order(:name)
end

# Semantic parameter handling
def archive
  @inspector_company.update(active: false)
  flash[:success] = t("inspector_companies.messages.archived")
  redirect_to inspector_companies_path
end
```

### Model Helper Methods (DRY)
```ruby
def can_create_inspection?
  has_inspection_company? && 
  inspection_company_active? && 
  within_inspection_limit?
end

private

def has_inspection_company?
  inspection_company_id.present?
end

def inspection_company_active?
  inspection_company&.active?
end

def within_inspection_limit?
  inspection_limit == -1 || inspections.count < inspection_limit
end
```

### DRY View Partials
```erb
<!-- app/views/inspector_companies/_archive_link.html.erb -->
<% if inspector_company.active? %>
  <%= link_to t('inspector_companies.buttons.archive'), 
        archive_inspector_company_path(inspector_company), 
        data: { turbo_method: :patch, turbo_confirm: "Are you sure?" } %>
<% else %>
  <%= link_to t('inspector_companies.buttons.unarchive'), 
        unarchive_inspector_company_path(inspector_company), 
        data: { turbo_method: :patch, turbo_confirm: "Are you sure?" } %>
<% end %>

<!-- Usage -->
<%= render 'archive_link', inspector_company: company %>
```

## Business Rules Examples

### User Access Control
- Users from archived companies cannot create new inspections
- Archived companies still appear in inspection history (data integrity)
- Only admins can see company notes fields
- Users can only see their own units and inspections

### Data Validation
- All forms validate required fields with clear error messages
- Use semantic field names: `inspection_location` not `location`
- Phone numbers are normalized on save
- Email addresses are validated and downcased

### UI/UX Patterns
- Default views show all data unless filtered (better discoverability)
- Use clear, semantic filter parameters: "active", "archived", "all"
- Confirmation dialogs for destructive actions
- Success/error flash messages for user feedback
- Auto-save forms for better UX (where appropriate)