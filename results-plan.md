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
1. **Update `inspection_tabs` helper** in `app/helpers/inspections_helper.rb`:
   - Add "results" tab after all assessment tabs
   - Ensure proper ordering (after "enclosed" if present)

2. **Create results assessment model** `app/models/results_assessment.rb`:
   - Include `AssessmentCompletion` concern
   - Define fields: `passed` and `risk_assessment`
   - Add to inspection's assessment associations

3. **Create migration** for `results_assessments` table:
   - Fields: `passed` (boolean), `risk_assessment` (text)
   - Foreign key to inspection
   - Migrate existing data from inspections table

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

### Phase 4: Update Inspection Model
1. **Remove fields from main form** (`_form.html.erb`):
   - Remove "Inspection Results" fieldset
   - Keep all other fields intact

2. **Update inspection model**:
   - Delegate `passed` and `risk_assessment` to results_assessment
   - Update `REQUIRED_TO_COMPLETE_FIELDS` if needed
   - Ensure `incomplete_fields` checks results_assessment

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

### Phase 7: Data Migration
1. **Create data migration**:
   - Copy existing `passed` and `risk_assessment` values
   - Ensure all inspections have results_assessment records

2. **Remove old columns** (after verification):
   - Drop columns from inspections table
   - Update any remaining references

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