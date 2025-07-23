# Inspection Location Removal - Test Updates Required

## Overview
The migration removes:
- `inspection_location` column from `inspections` table
- `default_inspection_location` column from `users` table

## Files to Update (31 total)

### 1. Model Specs
- **spec/models/inspection_spec.rb**
  - Lines 17-23: Remove validation test for `inspection_location` when complete
  
- **spec/models/concerns/public_field_filtering_spec.rb**
  - Line 80: Remove `inspection_location` from public fields list

### 2. Support Files
- **spec/support/inspection_test_helpers.rb**
  - Lines 40-42: Remove `fill_in_location` method
  
- **spec/support/json_test_helpers.rb**
  - Line 13: Remove `inspection_location` from expected fields

- **spec/support/shared_examples/pdf_generation.rb**
  - Lines 32-33: Remove `inspection_location` from unicode test
  - Lines 61-62: Remove `inspection_location` from long text test

### 3. Service Specs
- **spec/services/pdf_generator_service/table_builder_spec.rb**
  - Lines 193-195: Remove `inspection_location` parameter from inspection creation
  - Lines 242, 258, 273, 336: Remove inspection location from PDF headers/content
  
- **spec/services/json_serializer_service_spec.rb**
  - Line 233: Remove `inspection_location` from critical fields check

### 4. Request Specs
- **spec/requests/api/inspections_json_spec.rb**
  - Lines 16, 122: Remove inspection_location assertions
  
- **spec/requests/api/units_json_real_world_spec.rb**
  - Lines 15, 22: Remove `inspection_location` from inspection creation
  - Lines 54, 58: Remove location assertions

- **spec/requests/inspections/inspections_spec.rb**
  - Line 14: Remove `inspection_location` from params

- **spec/requests/turbo/turbo_streams_spec.rb**
  - Lines 13, 22, 31, 40, 51: Remove `inspection_location` from params

- **spec/requests/users/user_name_editing_security_spec.rb**
  - Lines 13, 21: Remove `default_inspection_location` references

### 5. Controller Specs
- **spec/controllers/inspections_controller_turbo_spec.rb**
  - Line 40: Remove `inspection_location` from validation test

### 6. View Specs
- **spec/views/inspector_companies/show.html.erb_spec.rb**
  - Line 127: Remove inspection location display check

### 7. Feature Specs
- **spec/features/inspections/inspection_incomplete_fields_spec.rb**
  - Lines 12, 54, 65, 78, 113-114, 135: Remove all incomplete field checks for inspection_location
  
- **spec/features/inspections/turbo_incomplete_fields_spec.rb**
  - Lines 10, 27-28: Remove inspection_location from incomplete fields test
  
- **spec/features/inspections/dirty_form_warning_spec.rb**
  - Lines 18, 31: Remove form filling tests for inspection_location

- **spec/features/inspections/inspections_csv_export_spec.rb**
  - Lines 13, 22, 49, 84-85, 93: Remove inspection_location from CSV tests

- **spec/features/inspections/inspections_index_spec.rb**
  - Lines 17, 24, 32, 61: Remove inspection_location from index display tests

- **spec/features/inspections/complete_inspection_workflow_spec.rb**
  - Line 45: Remove fill_in_location call

- **spec/features/inspections/indoor_only_field_spec.rb**
  - Line 15: Remove inspection_location from params

- **spec/features/inspections/inspection_prefill_spec.rb**
  - Lines 16, 21, 84, 92: Remove inspection_location from prefill tests

- **spec/features/inspections/assessment_access_control_spec.rb**
  - Line 64: Remove inspection location content check

- **spec/features/details_links_spec.rb**
  - Line 16: Remove inspection_location from test data

- **spec/features/pdfs/pdf_content_spec.rb**
  - Lines 17, 48, 67: Remove inspection_location from PDF content checks

- **spec/features/pdfs/pdf_generation_spec.rb**
  - Lines 23, 74, 105, 120, 136, 152, 168, 184, 200, 206: Remove all PDF location references

- **spec/features/security/inactive_user_restrictions_spec.rb**
  - Line 49: Remove inspection_location check

- **spec/features/ui/json_links_spec.rb**
  - Line 48: Remove inspection_location JSON check

- **spec/features/users/user_name_editing_permissions_spec.rb**
  - Lines 85, 90, 97: Remove default_inspection_location field tests

### 8. Other Specs
- **spec/seeds/seeds_spec.rb**
  - Lines 188, 518: Remove inspection_location presence checks

- **spec/lib/test_data_helpers_spec.rb**
  - Lines 157-186, 198, 208: Remove all inspection_location test data helper tests

## Actions Required

1. Remove all references to `inspection_location` field
2. Remove all references to `default_inspection_location` field  
3. Remove the `fill_in_location` helper method
4. Update tests that check for incomplete fields to not include inspection_location
5. Update PDF generation tests to not expect location in output
6. Update JSON API tests to not include location field
7. Remove location from factory/seed data creation
8. Remove TestDataHelpers.inspection_location method and its tests