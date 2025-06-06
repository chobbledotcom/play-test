# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands

- Run server: `rails s` or `bundle exec rails server`
- Rails console: `rails c`
- Lint autofix: `bundle exec rake standard:fix`
- Run all tests: `bundle exec rspec`
- Run single test: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- Run with verbose output: `bundle exec rspec --format documentation`

## Development Philosophy & Architecture

### Testing First Approach
- **ALWAYS write tests** - we have 954 tests with 84% coverage
- Use **RSpec** with descriptive contexts/examples
- Use **Capybara** for feature tests to test user workflows
- Use **Factory Bot** for test data creation
- Test both happy path and edge cases
- Write integration tests for complex user flows
- Use `--fail-fast` during development to fix issues incrementally

### Frontend & UI Principles
- **Minimal CSS** - use MVP.css framework for simple, semantic styling
- **Progressive enhancement** - start with working HTML, enhance with minimal JavaScript
- **Turbo-first** - use Turbo for form submissions and navigation
  - Use `data: { turbo_method: :patch }` instead of old Rails UJS `method: :patch`
  - Use `data: { turbo_confirm: "message" }` for confirmations
  - Auto-submit forms with `onchange: "this.form.submit();"`
- **Semantic HTML** - proper use of headers, sections, forms, tables
- **Accessibility** - proper labels, alt text, semantic structure

### Internationalization (i18n)
- **Never hardcode strings** - always use I18n keys
- Organize keys logically: `users.messages.company_archived`
- Use I18n in tests: `I18n.t("inspector_companies.buttons.archive")`
- Structure: `controller.section.key` or `model.field.description`

### Database & Models
- Use descriptive field names: `inspection_location` not `location`
- Write validations for data integrity
- Use scopes for complex queries: `InspectorCompany.by_status("active")`
- Make private helper methods for cleaner public interfaces
- Always validate associations and required fields

### Controllers & Business Logic
- Keep controllers thin - delegate to models/services
- Use semantic parameter names: "active", "archived", "all" not true/false strings
- Default to showing all data unless filtered (better UX)
- Use proper HTTP methods (PATCH for updates, not GET)
- Handle edge cases gracefully with flash messages

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
