# RSpec Test Failures Catalogue

**Total Failures: 117 failures out of 2305 examples**

## Summary by File

### 1. spec/models/enclosed_assessment_spec.rb (1 failure)
- **Method**: `#critical_failure_summary`
  - **Issue**: Text mismatch - expects "Exits not clearly visible" but gets "Exit signs not always visible"

### 2. spec/views/form/_pass_fail.html.erb_spec.rb (16 failures)
- **Method**: `render_pass_fail` helper
  - **Issue**: `undefined method 'radio_button' for nil` - form object is nil in view partial tests

### 3. spec/seeds/seeds_spec.rb (36 failures)
- **Primary Issues**:
  - `validation failed: Num low anchors can't be blank` for anchorage assessments
  - Various assessment models are not being properly created during seed data generation
  - All assessment types affected: anchorage, structure, materials, fan, user_height, slide, enclosed

### 4. spec/features/pdf_field_coverage_spec.rb (Multiple failures)
- **Issue**: PDF generation expecting fields that don't exist or have been renamed
- **Affected assessments**: All assessment types showing missing or renamed fields

### 5. spec/requests/inspections_csv_completeness_spec.rb (Multiple failures)
- **Issue**: CSV headers don't match expected fields - many renamed columns

### 6. spec/features/assessment_forms_spec.rb (1 failure)
- **Method**: Anchorage assessment form rendering
  - **Issue**: Missing required field `num_low_anchors`

### 7. spec/features/inspection_lifecycle_spec.rb (1 failure)
- **Issue**: Inspection completion failing due to assessment validation errors

### 8. spec/features/inspection_creation_workflow_spec.rb (1 failure)
- **Issue**: Form submission failing with anchorage assessment validation

### 9. spec/features/user_height_assessment_spec.rb (2 failures)
- **Issues**: 
  - Missing field `tallest_user_height_pass`
  - Incorrect form field expectations

### 10. spec/requests/pdf/pdf_i18n_coverage_spec.rb (1 failure)
- **Issue**: Missing translation keys for PDF generation

## Pattern Analysis

The failures appear to be caused by several systematic issues:

1. **Database column renaming pattern**: Many failures suggest columns have been renamed to follow a new "_pass" suffix pattern for pass/fail fields
2. **Assessment validation changes**: Required fields have been added/modified
3. **Form helper context**: View specs not properly setting up form context
4. **Seed data not updated**: Seed data service needs updates for new schema

## Top 10 Bang-for-Buck Fixes

Based on the failure patterns, here are the most impactful fixes to investigate:

1. **Fix SeedDataService assessment creation** (36 failures)
2. **Update pass/fail column references** (affects multiple specs)
3. **Fix form partial test setup** (16 failures)
4. **Update CSV export headers** (multiple failures)
5. **Fix anchorage assessment validations** (affects seeds and features)
6. **Update PDF field mappings** (affects PDF generation)
7. **Fix user height assessment fields** (2+ failures)
8. **Update enclosed assessment text** (1 failure but likely systemic)
9. **Fix form field expectations in feature specs** (multiple)
10. **Update translation keys** (affects PDF and possibly other areas)

---

## Detailed Analysis of Top 10 Fixes

### 1. Fix SeedDataService assessment creation (36 failures)

**Problem**: The seed data service creates anchorage assessments without required fields. The `num_low_anchors` and `num_high_anchors` fields are validated as required in the model but the seed service's `create_anchorage_assessment` method uses `update!` on an already-created assessment.

**Root Cause**: When an inspection is created, it automatically creates all assessments via the `after_create :create_assessments` callback in the Inspection model. These assessments are created with nil values for required fields. The seed service then tries to update them, but validation failures occur.

**Analysis of Code**:
- Line 223: `inspection.anchorage_assessment.update!` assumes the assessment exists
- Lines 224-225: Sets `num_low_anchors` and `num_high_anchors` 
- The model validation at app/models/assessments/anchorage_assessment.rb:8-10 requires these fields to be numeric (but allows blank)

**Potential Fix**: The validation actually allows blank values (`allow_blank: true`), so the issue might be in how the assessment is initially created. Need to check the inspection model's `create_assessments` method.

**UPDATE**: After investigation, the validations in anchorage_assessment.rb do allow blank values. The actual error must be coming from a different validation. Looking at the seed failures more closely, it appears the issue is that the seeds are trying to validate the complete inspection which expects certain fields to be present.

**Recommended Fix**: 
1. Check if there are any validations on the Inspection model that require assessment fields
2. Ensure seed data populates all required assessment fields before marking inspections as complete
3. The seed service should populate assessments immediately after creating the inspection, not wait until later

### 2. Update pass/fail column references (affects multiple specs)

**Problem**: Multiple test failures indicate that column names have changed to follow a new "_pass" suffix pattern. For example:
- `exit_visible_pass` renamed to `exit_sign_always_visible_pass` 
- Text expectations changed (e.g., "Exits not clearly visible" → "Exit signs not always visible")

**Evidence from Migrations**:
- Migration `20250613073729_rename_exit_visible_to_exit_sign_always_visible.rb` renamed these columns
- Multiple other migrations added "_pass" suffixed fields

**Affected Areas**:
1. `spec/models/enclosed_assessment_spec.rb` - expects old text "Exits not clearly visible"
2. CSV export specs expecting old column names
3. PDF generation expecting old field names
4. Feature specs checking for old field names in forms

**Recommended Fix**:
1. Update all spec files to use new column names with "_pass" suffix
2. Update expected text strings to match new wording
3. Search for all occurrences of old column names and update systematically
4. Update i18n translation keys to match new column names

### 3. Fix form partial test setup (16 failures)

**Problem**: The `spec/views/form/_pass_fail.html.erb_spec.rb` fails with `undefined method 'radio_button' for nil`. The partial expects `@_current_form` to be set but the test doesn't provide it.

**Root Cause**: 
- Line 8 in the partial: `form = @_current_form`
- The test mocks a form builder but doesn't set the instance variable
- The partial doesn't use the form_field_setup helper as expected

**Current Partial Code**:
```erb
form = @_current_form
<%= form.radio_button field, option_value, id: "#{field}_#{option_value}" %>
```

**Recommended Fix**:
1. Update the test to set `@_current_form` instance variable before rendering
2. OR update the partial to use the form_field_setup helper pattern
3. Ensure all form partial tests follow the same pattern for setting up form context

**Test Fix Example**:
```ruby
before do
  view.instance_variable_set(:@_current_form, mock_form)
end
```

### 4. Update CSV export headers (multiple failures)

**Problem**: CSV export tests expect columns that have been moved to assessment tables. Many fields were migrated from the inspections table to their respective assessment tables.

**Evidence from Migrations**:
- `20250612192000_remove_anchorage_fields_from_inspections.rb` - removed anchorage fields
- `20250612193000_remove_user_height_fields_from_inspections.rb` - removed user height fields
- `20250612194000_remove_structure_fields_from_inspections.rb` - removed structure fields
- `20250612173448_remove_slide_fields_from_inspections.rb` - removed slide fields
- And many others...

**Current Issue**: The CSV export service includes all inspection columns automatically, but many columns no longer exist in the inspections table - they've been moved to assessment tables.

**Recommended Fix**:
1. Update CSV export to NOT include moved columns automatically
2. Add assessment data to CSV export if needed (join with assessment tables)
3. Update tests to expect only columns that still exist in inspections table
4. Consider if CSV should include assessment data and implement accordingly

### 5. Fix anchorage assessment validations (affects seeds and features)

**Problem**: Multiple tests fail because anchorage assessment fields aren't being populated correctly. The seed data service was recently updated to use `ropes` instead of `rope_size` for materials assessment, but anchorage assessments still have issues.

**Column Renames Found**:
- Materials: `rope_size` → `ropes` (migration 20250613075220)
- Materials: `fabric_pass` → `fabric_strength_pass` (migration 20250613074826)
- Materials: `clamber_pass` → `clamber_netting_pass` (migration 20250613074826)

**Seed Data Service Issues**:
1. Line 267: Uses `ropes` field (correct after rename)
2. Line 268: Uses `ropes_pass` field (correct)
3. Line 275: Uses `fabric_strength_pass` (correct after rename)
4. Line 269: Uses `clamber_netting_pass` (correct after rename)

**Recommended Fix**:
1. Verify all assessment models have correct column names after migrations
2. Update seed data to use correct column names throughout
3. Ensure validations match actual column names
4. Run migration status check to ensure all migrations have been applied

### 6. Update PDF field mappings (affects PDF generation)

**Problem**: PDF generation tests fail because they expect fields that have been moved from the inspections table to assessment tables. The PDF generator needs to be updated to pull data from the correct assessment models.

**PDF Generator Structure**:
- Uses `AssessmentRenderer` class to generate assessment sections
- Generates sections for: user_height, slide, structure, anchorage, materials, fan, enclosed
- Each section should pull from its respective assessment model

**Issues Found**:
1. PDF tests expect fields that no longer exist on inspection model
2. Assessment data needs to be accessed via association (e.g., `inspection.anchorage_assessment.num_low_anchors`)
3. Field names have changed (e.g., `exit_visible_pass` → `exit_sign_always_visible_pass`)

**Recommended Fix**:
1. Update PDF generator to access fields from assessment models
2. Update field name references to match renamed columns
3. Ensure all assessment sections properly check for nil assessments
4. Update PDF tests to expect correct field names and structure

### 7. Fix user height assessment fields (2+ failures)

**Problem**: User height assessment tests fail due to renamed fields and missing pass/fail fields. The column `user_height` was renamed to `tallest_user_height` and new pass/fail fields were added.

**Column Changes**:
- Migration `20250609132048`: Renamed `user_height` → `tallest_user_height` across multiple tables
- Migration `20250613050416`: Added new pass/fail fields:
  - `height_requirements_pass`
  - `permanent_roof_pass`
  - `user_capacity_pass`
  - `play_area_pass`
  - `negative_adjustments_pass`

**Issues**:
1. Tests expect old field name `user_height`
2. Tests may expect `tallest_user_height_pass` field which doesn't exist
3. Form may be looking for wrong field names

**Recommended Fix**:
1. Update all references from `user_height` to `tallest_user_height`
2. Check which pass/fail fields actually exist in the model
3. Update form fields to match actual column names
4. Update tests to use correct field names

### 8. Update enclosed assessment text (1 failure but likely systemic)

**Problem**: The test expects "Exits not clearly visible" but the model returns "Exit signs not always visible". This is a simple text mismatch in the `critical_failure_summary` method.

**Code Analysis**:
- `spec/models/enclosed_assessment_spec.rb:117`: Expects "Exits not clearly visible"
- `app/models/assessments/enclosed_assessment.rb:40`: Returns "Exit signs not always visible"

**This indicates a pattern**: When column names changed, the associated display text also changed, but tests weren't updated.

**Recommended Fix**:
1. Update the test expectation to match the actual text
2. Search for all similar text expectations in tests
3. Consider using i18n keys for these messages instead of hardcoded strings
4. Make the messages consistent across the application

### 9. Fix form field expectations in feature specs (multiple)

**Problem**: Feature specs expect form fields that may have been renamed or restructured. The `assessment_forms_spec.rb` uses a helper method `expect_form_matches_i18n` which validates that form fields match the i18n structure.

**Pattern Observed**:
- Tests use `expect_form_matches_i18n(i18n_base)` to verify forms
- This helper checks that all fields defined in i18n are rendered
- If field names changed, the i18n keys need updating

**Common Issues**:
1. Field name mismatches between i18n and actual form fields
2. Missing i18n keys for new fields
3. Old field names still in i18n files

**Recommended Fix**:
1. Check i18n files for outdated field names
2. Update i18n keys to match new column names
3. Ensure form partials use correct field names
4. Run i18n usage tracker to find unused keys

### 10. Update translation keys (affects PDF and possibly other areas)

**Problem**: PDF i18n coverage test expects certain translation keys to be used in PDFs, but with field renames, these keys may have changed or become obsolete.

**Pattern**: When database columns are renamed, the corresponding i18n keys should also be updated, but this is often missed leading to:
- Missing translation errors
- Tests expecting old i18n keys
- Unused i18n keys remaining in locale files

**Common Translation Updates Needed**:
- Field labels for renamed columns
- Error messages referencing old field names
- PDF section headers and field names
- Form field labels and hints

**Recommended Fix**:
1. Run the i18n usage tracker to identify unused keys
2. Update locale files to remove old keys and add new ones
3. Ensure all renamed fields have corresponding i18n updates
4. Update tests to expect new i18n keys

## Summary

The majority of test failures stem from a systematic database refactoring where:
1. Fields were moved from the inspections table to assessment tables
2. Column names were standardized with "_pass" suffix for pass/fail fields
3. Some columns were renamed for clarity (e.g., `user_height` → `tallest_user_height`)

The fixes require systematic updates across:
- Model validations and methods
- Form partials and views
- Test expectations
- I18n translation files
- Service objects (CSV export, PDF generation, seed data)

The most impactful fixes would be:
1. Updating the seed data service to use correct column names (fixes 36 tests)
2. Fixing form partial test setup (fixes 16 tests)
3. Systematically updating all "_pass" field references
4. Updating CSV and PDF services to pull from assessment models
