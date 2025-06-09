# TODO List

This document lists all TODO comments found in the codebase.

## Model TODOs

### app/models/unit.rb
- **Line 87-88**: Use proper scopes for passed/failed inspections
  ```ruby
  passed_inspections: inspections.where(passed: true).count, # TODO: Use passed scope when available
  failed_inspections: inspections.where(passed: false).count, # TODO: Use failed scope when available
  ```
  **Action**: The Inspection model already has `passed` and `failed` scopes defined. These lines should be updated to use:
  - `inspections.passed.count`
  - `inspections.failed.count`

## Test TODOs

### spec/models/unit_spec.rb
- **Line 312-313**: Add missing tests for overdue functionality
  ```ruby
  # TODO: Add tests for overdue functionality once inspection relationship is enhanced
  # TODO: Add tests for last_due_date once inspection dates are properly implemented
  ```
  **Action**: These tests should be implemented now that the inspection relationship is fully functional. Tests needed:
  - Test for identifying overdue units based on inspection dates
  - Test for calculating last_due_date from inspections

### spec/views/home/index.html.erb_spec.rb
- **Line 160**: Assertion checking that TODO is not rendered
  ```ruby
  expect(rendered).not_to include("TODO")
  ```
  **Note**: This is not actually a TODO - it's a test ensuring no TODO text appears in the rendered view.

## Summary

Total TODOs found: 4 (excluding the test assertion)
- 2 in production code (both in unit.rb)
- 2 in test code (both in unit_spec.rb)

All TODOs appear to be straightforward fixes that can be implemented immediately.