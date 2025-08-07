# Assessment Gemification Guide

## Overview

This guide documents the process of migrating assessment-specific code from the main Rails application to the `en14960-assessments` gem.

## Methods Already Moved to Gem

The following assessment field generation methods have been moved from `/db/seeds/seed_data.rb` to `/gems/en14960-assessments/lib/en14960_assessments/seed_data.rb`:

- [x] `anchorage_fields` - Generates anchorage assessment data
- [x] `structure_fields` - Generates structure assessment data  
- [x] `materials_fields` - Generates materials assessment data
- [x] `fan_fields` - Generates fan assessment data
- [x] `user_height_fields` - Generates user height assessment data
- [x] `slide_fields` - Generates slide assessment data
- [x] `enclosed_fields` - Generates enclosed assessment data

✅ **Verified**: All methods exist in the gem at `/gems/en14960-assessments/lib/en14960_assessments/seed_data.rb`

## Guide for Migrating Assessment Seed Data Spec Tests

Based on the slide seed data migration, here's the pattern to follow for migrating the remaining assessment seed data spec tests:

### 1. Identify Assessment-Specific Tests

Look for spec files that test the assessment field generation methods:
- `anchorage_seed_data_spec.rb` - tests `.anchorage_fields`
- `structure_seed_data_spec.rb` - tests `.structure_fields` 
- `materials_seed_data_spec.rb` - tests `.materials_fields`
- `fan_seed_data_spec.rb` - tests `.fan_fields`
- `user_height_seed_data_spec.rb` - tests `.user_height_fields`
- `enclosed_seed_data_spec.rb` - tests `.enclosed_fields`

### 2. Migration Steps

For each assessment test file:

1. **Copy the file to the gem**:
   ```bash
   cp spec/seeds/[assessment]_seed_data_spec.rb gems/en14960-assessments/spec/en14960_assessments/
   ```

2. **Update the spec file**:
   - Change `require "spec_helper"` to `require "rails_helper"`
   - Update the describe block to use the gem module: `RSpec.describe En14960Assessments::SeedData`
   - Replace any `SeedData` references with `described_class`
   - Remove any dependencies on the main app's modules (like `EN14960`)

3. **Delete the original file** from the main repo

### 3. Common Transformations

#### Example transformation pattern:
```ruby
# OLD (in main repo)
require "spec_helper"
require Rails.root.join("db/seeds/seed_data")

RSpec.describe SeedData do
  describe ".anchorage_fields" do
    it "generates valid data" do
      fields = SeedData.anchorage_fields(passed: true)
      # ...
    end
  end
end

# NEW (in gem)
require "rails_helper"

RSpec.describe En14960Assessments::SeedData do
  describe ".anchorage_fields" do
    it "generates valid data" do
      fields = described_class.anchorage_fields(passed: true)
      # ...
    end
  end
end
```

### 4. Handle Dependencies

If tests depend on calculations from other modules (like the slide test depended on `EN14960`):
- Replace with inline calculations
- Or mock the external dependency if it's too complex

### 5. Verify Migration

After each migration:
1. Run the test in the gem: `cd gems/en14960-assessments && bundle exec rspec spec/en14960_assessments/[assessment]_seed_data_spec.rb`
2. Ensure the test passes
3. Check that no references to the deleted test remain in the main repo

### 6. Update References

Search for any references to the moved tests in:
- Other spec files
- Test helpers
- Documentation

### 7. Files That Need to Be Updated

When moving assessment seed data, these files typically need updates:

- `/db/seeds/inspections.rb` - Update to use `En14960Assessments::SeedData` for assessment methods
- `/app/services/seed_data_service.rb` - Update assessment field generation calls
- `/spec/features/inspections/complete_inspection_workflow_spec.rb` - Update conditional logic for assessment vs non-assessment tabs
- `/spec/features/inspections/inspection_screenshots_spec.rb` - Similar updates needed

This systematic approach ensures clean migration without breaking existing functionality.

## Verification Checklist

After migration is complete:
- [ ] All assessment field methods exist in the gem
- [ ] All tests pass in both the main app and the gem
- [ ] No references to deleted methods remain in the main app
- [ ] Seeds still generate correctly
- [ ] Integration tests still pass