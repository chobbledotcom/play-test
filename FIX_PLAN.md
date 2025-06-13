# Comprehensive Test Fix Plan

## Overview
117 failures caused by systematic database refactoring. Most failures fall into predictable patterns that can be fixed in batches.

## Fix Strategy: Group by Pattern, Not by File

### Phase 1: Column Rename Fixes (Est. 40-50 failures)
**Pattern**: Column names changed, need systematic find/replace

1. **Collect all column renames from migrations**
   ```bash
   grep -r "rename_column" db/migrate/ | grep -E "(assessments|inspections)" | sort
   ```

2. **Create a mapping of old → new names**:
   - `user_height` → `tallest_user_height`
   - `exit_visible_pass` → `exit_sign_always_visible_pass`
   - `rope_size` → `ropes`
   - `fabric_pass` → `fabric_strength_pass`
   - `clamber_pass` → `clamber_netting_pass`

3. **Batch fix approach**:
   ```bash
   # Find all spec files using old column names
   grep -r "user_height" spec/ --include="*.rb" | cut -d: -f1 | sort -u
   grep -r "exit_visible_pass" spec/ --include="*.rb" | cut -d: -f1 | sort -u
   grep -r "rope_size" spec/ --include="*.rb" | cut -d: -f1 | sort -u
   ```

4. **Fix each pattern across all files at once**

### Phase 2: Form Partial Test Setup (16 failures immediately)
**Pattern**: Form partials expect `@_current_form` instance variable

1. **Find all form partial specs**:
   ```bash
   ls spec/views/form/*.erb_spec.rb
   ```

2. **Add to each spec's before block**:
   ```ruby
   view.instance_variable_set(:@_current_form, mock_form)
   ```

### Phase 3: Assessment Field Access (Est. 30-40 failures)
**Pattern**: Fields moved from inspection to assessment models

1. **Identify moved fields from migrations**:
   ```bash
   grep -r "remove_column :inspections" db/migrate/ | grep -v "def change"
   ```

2. **Update field access pattern**:
   - OLD: `inspection.num_low_anchors`
   - NEW: `inspection.anchorage_assessment.num_low_anchors`

3. **Find and fix by assessment type**:
   - Anchorage fields: `num_low_anchors`, `num_high_anchors`, etc.
   - User height fields: `containing_wall_height`, `platform_height`, etc.
   - Materials fields: `ropes`, `fabric_strength_pass`, etc.

### Phase 4: Text/String Updates (Est. 5-10 failures)
**Pattern**: Display text changed when columns renamed

1. **Find hardcoded strings in specs**:
   ```bash
   grep -r "Exits not clearly visible" spec/
   grep -r "translation missing" spec/
   ```

2. **Update to match new text**:
   - "Exits not clearly visible" → "Exit signs not always visible"

### Phase 5: Service Object Updates (CSV/PDF)
**Pattern**: Services need to pull from assessment models

1. **CSV Export Service**:
   - Remove automatic inclusion of moved columns
   - Add explicit assessment data if needed

2. **PDF Generator Service**:
   - Already uses AssessmentRenderer
   - May just need field name updates

### Phase 6: Seed Data Service
**Pattern**: Already partially fixed, needs completion

1. **Verify all assessment creation methods use correct fields**
2. **Ensure assessments are created with required fields**

## Execution Order (Highest Impact First)

1. **Form Partial Fixes** (Quick win - 16 tests)
   - Simple fix, high impact
   - 5 minutes to implement

2. **Column Rename Batch Fixes** (40-50 tests)
   - Systematic find/replace
   - 30 minutes to implement

3. **Assessment Field Access Pattern** (30-40 tests)
   - More complex but predictable
   - 45 minutes to implement

4. **Text String Updates** (5-10 tests)
   - Quick fixes
   - 10 minutes

5. **Service Objects** (Remaining tests)
   - May require more investigation
   - 30 minutes

## Tools to Use

1. **Find affected files efficiently**:
   ```bash
   # Create a list of all failing spec files
   ./bin/test 2>&1 | grep "rspec ./spec" | cut -d' ' -f2 | sort -u > failing_specs.txt
   ```

2. **Check migration history**:
   ```bash
   # See all column changes in order
   grep -E "(rename_column|remove_column|add_column)" db/migrate/*.rb | grep -E "(assessments|inspections)"
   ```

3. **Verify fixes incrementally**:
   ```bash
   # Run specific test file after fixing
   bundle exec rspec spec/views/form/_pass_fail.html.erb_spec.rb
   ```

## Expected Results

- Phase 1-2: ~66 tests passing (56% reduction)
- Phase 3-4: ~45 more tests passing (38% reduction)  
- Phase 5-6: Remaining ~6 tests

Total time estimate: 2-3 hours for all fixes

## Key Principles

1. **Fix patterns, not individual tests** - If you see an error pattern, find ALL instances
2. **Use grep to find all occurrences** - Don't fix one-by-one
3. **Run tests after each phase** - Verify progress
4. **Update both test and implementation** - Some fixes might be in the actual code, not just tests