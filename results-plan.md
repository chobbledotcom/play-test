## Comprehensive Plan: Add "Results" Tab for Passed and Risk Assessment Fields

### Overview
Create a new "Results" tab that contains only the "passed" and "risk_assessment" fields, placed after all assessment tabs. This will require moving these fields from the main inspection form and updating tests to accommodate this change.

### Phase 1: Understanding & Setup
1. **Identify key test files to run frequently:**
   - `spec/features/inspections/complete_inspection_workflow_spec.rb`
   - `spec/features/inspections/inspection_incomplete_fields_spec.rb`
   - `spec/features/inspections/inspection_lifecycle_spec.rb`
   
2. **Quick test command:**
   ```bash
   bundle exec rspec spec/features/inspections/complete_inspection_workflow_spec.rb spec/features/inspections/inspection_incomplete_fields_spec.rb spec/features/inspections/inspection_lifecycle_spec.rb
   ```

### Phase 2: Create the Results Tab Infrastructure
1. **Update `inspection_tabs` method** in `app/models/inspection.rb`:
   - Add "results" tab after all assessment tabs
   - Ensure proper ordering (after "enclosed" if present)

2. **Update `assessment_complete?` helper** in `app/helpers/inspections_helper.rb`:
   - Add special case for "results" tab
   - Check if `passed` field is present (risk_assessment is optional)

### Phase 3: Create Results Form View
1. **Create `app/views/inspections/_results_form.html.erb`**:
   - Use standard form_context partial
   - Include pass_fail field for "passed"
   - Include text_area for "risk_assessment"

2. **Add i18n translations** in `config/locales/forms.en.yml`:
   - Create `forms.results` section
   - Add field labels and submit button text

3. **Update tab navigation** in `edit.html.erb`:
   - Ensure results tab appears in correct position
   - Add completion checkmark logic

### Phase 4: Update Main Inspection Form
1. **Remove fields from main form** (`_form.html.erb`):
   - Remove "Inspection Results" fieldset containing `passed` and `risk_assessment`
   - Keep all other fields intact

2. **Update inspection model completion logic**:
   - Ensure `inspection_model_incomplete_fields` excludes `passed` from the main tab check (since it's moving to results tab)
   - The `passed` field remains required for overall completion

### Phase 5: Update Controllers
1. **Add results tab handling** to `inspections_controller.rb`:
   - Add "results" to allowed tabs in `edit` action
   - Handle results_assessment creation/update

2. **Update Turbo responses**:
   - Ensure Turbo Stream updates work for results tab
   - Update tab completion indicators

### Phase 6: Fix Breaking Tests (Iterative Approach)
1. **Run key tests after each change**:
   - Fix test failures as they occur
   - Update test expectations for new tab structure

2. **Common test updates needed**:
   - Update feature tests to navigate to results tab
   - Update field filling helpers to handle new location
   - Update completion validation tests

3. **Update test helpers**:
   - Modify helpers that fill in inspection forms
   - Add navigation to results tab where needed

### Phase 7: No Data Migration Needed
Since `passed` and `risk_assessment` remain on the Inspection model, no data migration is required. The fields are simply being displayed in a different tab.

### Testing Strategy
- Run focused tests after each small change
- Fix failures immediately before proceeding
- Use `bin/rspec-find` to identify exact failure points
- Use `bin/rspec-replace` to test fixes without editing files

### Key Considerations
- Make small, reviewable changes
- Maintain backwards compatibility during migration
- Ensure all i18n keys are properly set up
- Keep existing validation logic intact
- Test with both new and existing inspections