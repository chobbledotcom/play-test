# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands

- Run server: `rails s` or `bundle exec rails server`
- Rails console: `rails c`
- **Lint modified files only**: `bundle exec standardrb --fix path/to/file.rb` (NEVER run on entire repo)
- Lint check (no fix): `bundle exec standardrb path/to/file.rb`
- **ERB files don't need linting with standardrb**
- **Run tests (parallel)**: `bin/test` (RECOMMENDED - clean output with coverage summary)
- **Check code standards**: `rake code_standards` (reports violations)
- **Lint modified files**: `rake code_standards:lint_modified` (StandardRB on changed files only)
- **Full standards workflow**: `rake code_standards:fix_all` (StandardRB + standards check)
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

## Test Helper Scripts

### Finding Test Failures (`bin/rspec-find`)

- **Purpose**: Quickly identify the first failing test with detailed information
- **Usage**: `bin/rspec-find [options] [rspec_args]`
- **Options**:
  - `-h, --help`: Show help message
- **Examples**:
  ```bash
  bin/rspec-find                      # Run all tests
  bin/rspec-find spec/models/         # Run only model specs
  bin/rspec-find spec/features/       # Run only feature specs
  bin/rspec-find spec/models/user_spec.rb  # Run specific file
  ```
- **Output**:
  - File path, line number, and test description
  - Full error message and backtrace
  - Complete test method code (with line numbers)
  - Copy-pasteable examples for using `rspec-replace`
- **Features**:
  - Runs `rspec --fail-fast` to stop at first failure
  - Shows progress dots while running
  - Parses JSON output for accurate failure details
  - Extracts test method boundaries automatically
  - Clear success message when all tests pass

### Replacing Test Code (`bin/rspec-replace`)

- **Purpose**: Test replacements for broken tests without editing files
- **Usage**: `bin/rspec-replace [options] FILE:LINE REPLACEMENT_CODE`
- **Options**:
  - `-w, --write`: Write changes to file if tests pass and line count is reasonable
  - `-h, --help`: Show help message
- **Examples**:

  ```bash
  # Single line replacement (test only)
  bin/rspec-replace spec/models/user_spec.rb:42 'it "works" do; expect(true).to be true; end'

  # Multi-line replacement (test only)
  bin/rspec-replace spec/models/user_spec.rb:42 'it "validates email format" do
    user = build(:user, email: "invalid")
    expect(user).not_to be_valid
  end'

  # Automatically write changes if tests pass
  bin/rspec-replace --write spec/models/user_spec.rb:42 'it "fixed test" do
    # Fixed implementation
  end'
  ```

- **Features**:
  - Automatically detects test boundaries (it/scenario/describe/context blocks)
  - Preserves proper indentation
  - Runs the modified test without changing the actual file
  - Shows original file paths in error messages
  - **Auto-write safety**: With `--write`, only writes if:
    - Tests pass
    - Line count doesn't change by more than 10 lines
  - Shows line count changes and suggestions
- **Workflow**:
  1. Run `bin/rspec-find` to identify failing test
  2. Use `bin/rspec-replace` to test fixes
  3. Once working, either:
     - Add `--write` to auto-apply the fix
     - Manually apply the fix to the file

## Core Development Principles

### Internationalization (i18n) - ALWAYS

- **EVERY string must use I18n** - no hardcoded text anywhere
- **Split locale files** - create new files in `config/locales/` instead of growing `en.yml`
- Organize keys logically: `users.messages.company_archived`
- Use I18n in tests: `I18n.t("inspector_companies.buttons.archive")`
- Structure: `controller.section.key` or `model.field.description`

### Form Conventions - STRICT REQUIREMENTS

All forms must follow these exact patterns:

1. **Always use form_context partial** for form wrapper:

   ```erb
   <%= render 'form/form_context',
     model: @model,
     i18n_base: 'forms.form_name' do |form|
   %>
   ```

2. **I18n structure for forms** - ALL forms must use `forms.` namespace:

   ```yaml
   en:
     forms:
       form_name:
         header: "Form Title" # Automatically rendered by form_context
         sections:
           section_name: "Section Title"
         fields: # ALL field labels MUST be in .fields namespace
           field_name: "Field Label"
           another_field: "Another Label"
         submit: "Submit Button Text" # Used by submit_button partial
   ```

3. **Field helpers expect translations in .fields namespace**:

   - `form_field_setup` looks for labels at `#{i18n_base}.fields.#{field}`
   - NO fallbacks - if field translation missing, it should error
   - This ensures all forms are properly internationalized

4. **Submit button automatically uses i18n**:

   ```erb
   <%= render 'form/submit_button' %>  # Looks for #{i18n_base}.submit
   ```

   - Never pass text parameter unless overriding default behavior
   - Submit button should find text at `#{@_current_i18n_base}.submit`

5. **Form partials set context automatically**:

   - `form_context` sets `@_current_form` and `@_current_i18n_base`
   - All nested partials can access these without passing parameters
   - Field partials use `form_field_setup` to get labels from i18n

6. **Standard form structure**:

   ```erb
   <%= render 'form/form_context',
     model: @model,
     i18n_base: 'forms.name' do |form|
   %>
     <%= render 'form/fieldset', legend_key: 'section_name' do %>
       <%= render 'form/text_field', field: :field_name %>
       <%= render 'form/pass_fail_comment', field: :check_name %>
     <% end %>
   <% end %>
   ```

   - Submit button is AUTOMATICALLY included by form_context
   - Never manually add submit buttons

7. **Non-model forms use scope**:
   ```erb
   <%= render 'form/form_context',
     model: nil,
     scope: :session,
     i18n_base: 'forms.session_new',
     url: login_path do |form|
   %>
   ```

### Testing Approach

- **Before editing ANY file** - identify what tests/test files are associated with it
- **Write Capybara tests for ALL new code** - no exceptions
- **No JavaScript in tests** - test the non-JS fallback behavior
- **Run tests immediately after editing** - run associated tests as soon as you edit a file
- **Never build up a backlog** - fix broken tests immediately, don't accumulate issues
- **NEVER delete tests unless 100% unnecessary** - fix rather than delete tests
- **Never delete tests that would reduce coverage** - always maintain or increase test coverage
- Use **RSpec** with descriptive contexts/examples
- Use **Factory Bot** for test data creation
- Test both happy path and edge cases
- Use `--fail-fast` during development to fix issues incrementally

#### RSpec DSL Conventions

Use the appropriate DSL based on test type:

**Feature/System Tests** (user interactions in `spec/features/`):

```ruby
RSpec.feature "User login", type: :feature do
  background do
    # setup (same as before)
  end

  scenario "successful login" do
    # test user interactions
  end
end
```

**All Other Tests** (models, controllers, services, helpers):

```ruby
RSpec.describe User, type: :model do
  describe "#method_name" do
    context "when condition" do
      it "does something" do
        # test implementation
      end
    end
  end
end
```

**DSL Mapping:**

- `feature` = `describe` (for feature tests only)
- `scenario` = `it` (for feature tests only)
- `background` = `before` (for feature tests only)
- Use standard RSpec DSL (`describe`, `context`, `it`, `before`) for all non-feature tests

**IMPORTANT: Pattern Recognition & Batch Fixes**

- **When you spot a pattern** - use `grep` to find all occurrences
- **Fix similar issues together** - don't fix one-by-one when pattern is clear
- **Common patterns to batch-fix**:
  - Manual assessment creation: `grep -r "create(:.*_assessment.*inspection:" spec/`
  - Hardcoded strings: `grep -r '"Some Text"' spec/`
  - Missing i18n: `grep -r 'have_content("' spec/`
- **Always verify pattern** - check a few examples before batch fixing
- **Use tools efficiently** - `cut`, `sort`, `uniq` to identify affected files

#### What's Already Tested (Avoid Duplication)

- **Form i18n coverage**: `spec/features/assessment_forms_spec.rb` uses `expect_form_matches_i18n()` to verify ALL form sections and fields are rendered
- **Form i18n structure**: `spec/lib/form_i18n_structure_spec.rb` validates form locale file structure
- **i18n usage tracking**: `lib/i18n_usage_tracker.rb` tracks all i18n key usage and finds unused keys
- **Helper methods available**: `expect_form_sections_present()`, `expect_form_fields_present()`, `expect_form_matches_i18n()`
- **DON'T write tests checking specific field presence** - the i18n coverage tests already verify this comprehensively

#### Helper Method Guidelines

- **Only extract helper methods when they add value**:
  - Used multiple times (DRY principle)
  - Hide genuinely complex logic that obscures test intent
  - Provide meaningful abstractions
- **Don't extract single-use methods** - if a method is only called once, it just splits logic unnecessarily
- **Keep test flow readable** - the test should tell a clear story without jumping to many helper methods
- **Inline simple expectations** - `expect(page).to have_content("text")` doesn't need a helper method

```ruby
# GOOD - Helper method used multiple times
def sign_in_as_admin
  sign_in(admin_user)
end

# GOOD - Complex logic that helps readability
def expect_all_dimensions_copied(source, target)
  %w[width length height has_slide].each do |attr|
    expect(target.send(attr)).to eq(source.send(attr)), "#{attr} should be copied"
  end
end

# BAD - Single-use method that just splits logic
def expect_page_title_present
  expect(page).to have_content(I18n.t("about.title"))
end

# GOOD - Just inline it instead
scenario "displays page title" do
  visit about_path
  expect(page).to have_content(I18n.t("about.title"))
end
```

### Test Coverage Analysis

#### Coverage Targets & Reports

- **Coverage target**: 100% line and branch coverage for all files
- **HTML report**: `coverage/index.html` (detailed view with line-by-line coverage)
- **JSON data**: `coverage/.resultset.json` (raw coverage data from parallel test runs)
- **Coverage thresholds**:
  - Green (>90%): Good coverage
  - Yellow (80-90%): Needs improvement
  - Red (<80%): Poor coverage requiring immediate attention

#### Quick Coverage Commands

```bash
# Check coverage for a specific file (extracts from HTML report)
ruby coverage_check.rb app/models/user.rb
ruby coverage_check.rb app/controllers/users_controller.rb

# View HTML report for detailed line-by-line analysis
# Open coverage/index.html in browser
```

#### Coverage Analysis Tool

**File Coverage Check** (`coverage_check.rb`):

- **Usage**: `ruby coverage_check.rb <file_path>`
- **Output**: Exact same figures as SimpleCov HTML report
- **Example output**:
  ```
  app/controllers/users_controller.rb: 86.21% lines covered
  87 relevant lines. 75 lines covered and 12 lines missed.
  76.67% branches covered
  30 total branches, 23 branches covered and 7 branches missed.
  ```
- **Use when**: Checking coverage after editing a specific file

#### Coverage Workflow

1. **After editing a file**: Run `ruby coverage_check.rb <file_path>` to check coverage
2. **Before committing**: Ensure no coverage regression
3. **When coverage drops**: Write tests for uncovered lines immediately
4. **Focus areas**: Controllers, services, models (business logic)
5. **HTML report**: Use for detailed line-by-line analysis when needed

#### Coverage Standards

- **Target**: >90% line coverage, >80% branch coverage for all files
- **Priority files**: Controllers, services, models with business logic
- **Low coverage files**: Immediate attention required for < 80% coverage

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
- **Trust our own interfaces** - avoid `respond_to?` checks for methods we control; we know what our objects support
- **ABSOLUTELY NO hardcoded strings** - every user-facing string must use I18n, no exceptions
- **ABSOLUTELY NO unused methods** - delete any method that isn't called; unused code is technical debt
- **Update old code** - don't support legacy patterns, refactor to new standards
- **Use modern Ruby syntax** - leverage Ruby 3.0+ features for cleaner, more expressive code
- **Prioritise readability** - choose the newest, tidiest syntax that improves code clarity
- **Prefer to crash than quietly fail** - raise exceptions for error conditions, don't return false/nil
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

### Modern Ruby Syntax Preferences (Ruby 3.0+)

**Always prefer the newest, tidiest syntax available:**

- **Endless methods** for simple computation: `def total = a + b`
- **Hash shorthand** when key matches method: `{width:, height:}`
- **Numbered parameters** in simple blocks: `map { _1.upcase }`
- **Pattern matching** for complex dispatch: `case type in "foo" then ...`
- **Rightward assignment** for clarity: `(a * b) => result`
- **Enhanced safe navigation**: `value&.method&.chain || default`
- **Modern enumerable methods**: `Hash#except`, `Enumerable#filter_map`

**Critical principle: Avoid unnecessary methods:**

- **Never create methods that just return constants** - use the constant directly
- **Use I18n for all user-facing strings** - no hardcoded English text
- **Endless methods should perform computation** - not just return static values

**String Interpolation Rule:**

- **Extract variables for complex interpolations** - nothing more complex than a single word with underscores should appear between `#{}` brackets
- Extract `#{hash[:key]}`, `#{object.method}`, `#{complex + calculation}` to variables first
- Keep simple: `#{variable}`, `#{method_name}`, `#{simple_var}`

**When refactoring, always upgrade to modern syntax** - don't maintain legacy patterns for compatibility

## Rails Style Guide & Code Standards

### Line Length & Formatting Standards (80 chars max)

**Breaking Long Lines (StandardRB Compatible):**

StandardRB will collapse excess whitespace, so use minimal formatting:

```ruby
# GOOD - Arrays/hashes: alphabetical order when order doesn't matter
ALLOWED_FORMATS = %i[csv json pdf xml]  # Alphabetical, under 80 chars

# GOOD - Break one per line when over 80 chars, maintain alphabetical order
LONGER_FORMAT_LIST = %i[
  csv
  docx
  html
  json
  pdf
  xml
]

# GOOD - Method calls: extract variables instead of parameter alignment
long_method_name = some_object.very_long_method_name
result = long_method_name(first_parameter, second_parameter, third_parameter)

# OR break at method call
some_object
  .very_long_method_name(first_parameter, second_parameter, third_parameter)

# GOOD - Hash parameters: extract variables for readability
user_params = { email: "test@example.com", name: "Test User", active: true }
create(:user, user_params)

# GOOD - Use Ruby shorthand hash syntax when key matches method name
def basic_attributes
  {width:, length:, height:, width_comment:, length_comment:}
end

# BAD - Redundant explicit assignment
def basic_attributes
  {width: width, length: length, height: height}
end

# GOOD - Use endless methods for simple one-liners (Ruby 3.0+)
def total_anchors = (num_low_anchors || 0) + (num_high_anchors || 0)
def max_capacity = user_capacity_values.compact.max || 0

# BAD - Traditional method definition for simple cases
def total_anchors
  (num_low_anchors || 0) + (num_high_anchors || 0)
end

# GOOD - Use numbered parameters in blocks (Ruby 2.7+)
methods.grep(/=$/).map { _1.to_s.chomp("=") }
attributes.map { unit.send(_1) }

# BAD - Unnecessary block parameter names
methods.grep(/=$/).map { |m| m.to_s.chomp("=") }
attributes.map { |attr| unit.send(attr) }

# GOOD - Pattern matching for complex dispatch (Ruby 3.0+)
case calculation_type
in "anchors" then calculate_anchors
in "user_capacity" then calculate_user_capacity
in "slide_runout" then calculate_slide_runout
else handle_unknown_type
end

# GOOD - Rightward assignment for complex expressions (Ruby 3.0+)
def build_result(length, width, adjustment)
  (length * width) => area
  (area - adjustment) => usable_area
  # ... rest of method
end

# GOOD - Enhanced safe navigation and modern syntax
def format_dimension(value) = value&.to_s&.sub(/\.0$/, "") || ""

# GOOD - Constants for static values, endless methods for computation
SAFETY_CHECK_COUNT = MATERIAL_CHECKS.length
def passed_checks_count = MATERIAL_CHECKS.count { _1 == true }  # Actual computation

# GOOD - Use constants directly in views and other models
<%= MaterialsAssessment::SAFETY_CHECK_COUNT %>

# GOOD - Handle different assessment types explicitly
case assessment
when MaterialsAssessment
  MaterialsAssessment::SAFETY_CHECK_COUNT
else
  assessment.respond_to?(:safety_check_count) ? assessment.safety_check_count : 0
end

# BAD - Method that just returns a string
def fabric_requirement = "Fabric tensile strength: 1850N minimum"

# GOOD - Use I18n for user-facing strings
I18n.t("materials_assessment.requirements.fabric_tensile")

# BAD - Method that just transforms a constant
def total_checks = CHECKS.length

# GOOD - Just use the constant directly
TOTAL_CHECKS = CHECKS.length
# Update callers to use TOTAL_CHECKS instead of total_checks method

# GOOD - Long strings: extract to variables (NEVER use backslash continuation)
error_msg = "This is a very long error message that needs to be broken across multiple lines for readability"

# GOOD - For very long strings, extract to variables FIRST
base_msg = "This is a very long error message that needs to be broken"
full_msg = "#{base_msg} across multiple lines for readability"

# BAD - NEVER use backslash continuation for strings
error_msg = "This is a very long error message that needs to be broken " \
            "across multiple lines for readability"

# GOOD - Comments: break at sentence boundaries (StandardRB preserves these)
# This is a long comment that explains the business logic
# and should be broken at natural sentence boundaries

# GOOD - SQL queries: use heredoc with line breaks before OR/AND
scope :search, ->(query) {
  if query.present?
    search_term = "%#{query}%"
    where(<<~SQL, search_term, search_term, search_term, search_term, search_term)
      serial LIKE ?
      OR name LIKE ?
      OR description LIKE ?
      OR manufacturer LIKE ?
      OR owner LIKE ?
    SQL
  else
    all
  end
}

# BAD - Long SQL on single line
where("serial LIKE ? OR name LIKE ? OR description LIKE ? OR manufacturer LIKE ? OR owner LIKE ?",
      search_term, search_term, search_term, search_term, search_term)

# BAD - All on one line when over 80 chars
LONG_FORMATS = [:pdf, :csv, :json, :xml, :html, :txt, :docx, :xlsx]
```

**Array Ordering & Length Rules:**

```ruby
# GOOD - Alphabetical order when order doesn't matter
validates :email, :name, presence: true
SIMPLE_ARRAY = %i[active archived inactive]

# GOOD - One per line when over 80 chars, alphabetical order
before_action :set_user, only: %i[
  change_password
  change_settings
  destroy
  edit
  impersonate
  update
  update_password
  update_settings
]

# BAD - Random order, hard to scan
SIMPLE_ARRAY = %i[inactive active archived]
```

### Method Design Principles

- **Maximum 20 lines per method** - if longer, extract private methods or delegate to other objects
- **Single responsibility** - each method should do one thing well
- **Descriptive names** - `calculate_total_tax` not `calc_tax` or `get_tax`
- **No deep nesting** - use guard clauses and early returns
- **Extract complex conditions** - use predicate methods like `user.can_edit_inspection?`

### Comments Policy

- **Only comment WHY, never WHAT** - code should be self-explanatory about what it does
- **Comments explain business context** - regulatory requirements, edge cases, non-obvious decisions
- **No redundant comments** - `user.save # saves the user` is pointless
- **Self-documenting code first** - use descriptive method/variable names instead of comments
- **Remove outdated comments** - incorrect comments are worse than no comments
- **Use British English** - in comments, variable names, and method names (colour not color, organised not organized)

### Object-Oriented Design

- **Fat models, skinny controllers** - business logic belongs in models
- **Use service objects** for complex operations that span multiple models
- **Value objects** for data that doesn't belong in the database (calculations, transformations)
- **Concerns for shared behavior** - but prefer composition over inheritance
- **Delegate appropriately** - `delegate :name, to: :company, prefix: true`

### DRY Principles (Done Right)

- **DRY code, not DRY tests** - test clarity trumps test brevity
- **Extract methods for business logic** - not just to reduce lines
- **Partial extraction** - when the same view logic appears 3+ times
- **Don't abstract too early** - wait until you see the pattern clearly
- **Readable duplication > clever abstraction** - if it makes tests harder to understand, don't do it

### Rails Conventions (Always Follow)

- **Use Rails idioms** - `find_by` not `where(...).first`
- **Leverage ActiveRecord** - scopes, validations, callbacks where appropriate
- **RESTful routes** - use Rails routing helpers, avoid custom routes unless necessary
- **Standard CRUD actions** - index, show, new, create, edit, update, destroy
- **Rails naming conventions** - no exceptions, update old code to match

### No Backwards Compatibility Code

- **Update all references** when changing method signatures
- **Refactor immediately** - don't leave deprecated code paths
- **Fix at the source** - don't work around old patterns
- **Consistent codebase** - all code should follow current standards
- **Delete unused code** - if it's not called, remove it

### Factory Design (Test Data)

- **Minimal factories** - only set required attributes and uniqueness constraints
- **Use traits for variations** - `:with_company`, `:archived`, `:admin`
- **Factory inheritance** sparingly - prefer traits over factory hierarchies
- **Realistic but simple data** - "Test User" not "John Smith from New York"
- **Avoid factory dependencies** - each factory should be independently creatable

**IMPORTANT: Inspection Factory Behavior**

- **NEVER manually create assessments** - they already exist, just update them
- **Assessment factories are for standalone testing only** - not for inspection tests

### Method Length & Complexity Examples

```ruby
# GOOD - Short, focused methods
def archive_company
  update(active: false)
  notify_users_of_archival
  log_archival_event
end

private

def notify_users_of_archival
  users.each { |user| UserMailer.company_archived(user).deliver_later }
end

def log_archival_event
  Rails.logger.info "Company #{name} archived by #{Current.user&.email}"
end

# BAD - Too long, multiple responsibilities
def archive_company_and_handle_everything
  # 25+ lines of mixed concerns
end
```

### Object Usage Examples

```ruby
# GOOD - Service object for complex operations
class InspectionCompletionService
  def initialize(inspection)
    @inspection = inspection
  end

  def complete
    validate_completion_requirements
    mark_as_complete
    generate_completion_report
    notify_stakeholders
  end

  private
  # ... implementation
end

# Usage in controller
def complete
  service = InspectionCompletionService.new(@inspection)
  if service.complete
    flash[:success] = t("inspections.messages.completed")
    redirect_to @inspection
  else
    render :show
  end
end
```

### Factory Examples

```ruby
# GOOD - Minimal factory
FactoryBot.define do
  factory :user do
    email { "user#{rand(10000)}@example.com" }
    password { "password123" }

    trait :admin do
      email { "admin#{rand(10000)}@example.com" }
    end

    trait :with_company do
      association :inspection_company
    end
  end
end

# BAD - Over-specified factory
FactoryBot.define do
  factory :user do
    first_name { "John" }
    last_name { "Smith" }
    email { "john.smith.#{rand(10000)}@example.com" }
    password { "SuperSecurePassword123!" }
    phone { "+1-555-123-4567" }
    created_at { 1.day.ago }
    # ... unnecessary details
  end
end
```

### Test Clarity Examples

```ruby
# GOOD - Clear test even with some duplication
RSpec.describe "User archiving" do
  it "prevents login when user is archived" do
    user = create(:user, active: false)
    post sessions_path, params: { email: user.email, password: "password123" }
    expect(response).to redirect_to(new_session_path)
    expect(flash[:error]).to include("account is inactive")
  end

  it "allows login when user is active" do
    user = create(:user, active: true)
    post sessions_path, params: { email: user.email, password: "password123" }
    expect(response).to redirect_to(dashboard_path)
  end
end

# BAD - DRY but unclear
RSpec.describe "User archiving" do
  let(:user) { create(:user, active: user_active) }
  let(:expected_redirect) { user_active ? dashboard_path : new_session_path }

  [true, false].each do |status|
    context "when user active is #{status}" do
      let(:user_active) { status }
      it "handles login appropriately" do
        # ... test logic that's hard to follow
      end
    end
  end
end
```

### Comments

## Good:

- Explains WHY, business context (British English)
- Explains non-obvious business rule
- British English in variable names
- No comment needed, method name is clear

## Bad:

- American English spelling
- Explains WHAT the code does (obvious)

## Established Patterns & Examples

### Testing Patterns

```ruby
# Feature tests with Capybara
RSpec.feature "Inspector Company Archiving", type: :feature do
  let(:admin_user) { create(:user, :admin) }

  before do
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
