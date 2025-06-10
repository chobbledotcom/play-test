# RPII Inspection System Migration Plan

## Overview

This document outlines a comprehensive, incremental migration plan to transform the basic testlog Rails application into a full-featured RPII (Recreational Play Inspection Institute) inspection system. The migration will transplant all functionality from `./app` into `./testlog`, upgrading "equipment" to "units" and "inspections" to include comprehensive safety assessments.

## Migration Strategy

- **Incremental**: Each step builds on the previous one
- **Testable**: Every step can be validated via RSpec
- **Backwards Compatible**: Existing functionality continues working during migration
- **Rollback Safe**: All database changes include proper rollback migrations
- **Small Steps**: Changes are easily reviewable and understandable

## Test Command

To run tests at each step:
```bash
cd /home/user/git/play-test/testlog && nix develop --command bash -c "bundle exec rspec"
```

## Current State Analysis

### TestLog App (`./testlog`)
- **Models**: Basic Equipment, Inspection, User
- **Database**: Simple schema with basic fields
- **Features**: Equipment tracking, basic inspections, user management
- **ID Strategy**: SecureRandom.alphanumeric(12).downcase

### Target App (`./app`)
- **Models**: Advanced Unit, Inspection, InspectorCompany, 7 Assessment types
- **Database**: Comprehensive schema with specialized assessment tables
- **Features**: Full inspection workflow, compliance tracking, safety standards
- **ID Strategy**: CustomIdGenerator with SecureRandom.alphanumeric(8).upcase

## Migration Phases

---

## Phase 1: Foundation (Steps 1-3)

### Step 1: Add CustomIdGenerator Concern

**Objective**: Establish consistent ID generation across all models

**Changes**:
- Create `app/models/concerns/custom_id_generator.rb`
- Standardize ID generation to match target system (uppercase alphanumeric)
- Prepare for models that will use this concern

**Files Affected**:
- `app/models/concerns/custom_id_generator.rb` (new)

**Migration**: None required

**Tests**:
- Verify concern can be included in models
- Test ID generation uniqueness and format
- Ensure existing Equipment/Inspection IDs remain unchanged

**Backwards Compatibility**: Full - existing models continue using current ID generation

---

### Step 2: Create InspectorCompany Model

**Objective**: Add company credential and branding management

**Changes**:
- Create migration for `inspector_companies` table
- Create `InspectorCompany` model with validations
- Include photo attachment support (logo)
- Add RPII verification and contact management

**Files Affected**:
- `db/migrate/xxx_create_inspector_companies.rb` (new)
- `app/models/inspector_company.rb` (new)
- `spec/models/inspector_company_spec.rb` (new)

**Database Schema**:
```ruby
create_table :inspector_companies, id: false do |t|
  t.string :id, primary_key: true, null: false, limit: 12
  t.references :user, null: false, foreign_key: true
  t.string :name, null: false
  t.string :rpii_registration_number, null: false
  t.string :email
  t.string :phone, null: false
  t.text :address, null: false
  t.string :city, :state, :postal_code
  t.string :country, default: 'UK'
  t.boolean :rpii_verified, default: false
  t.boolean :active, default: true
  t.text :notes
  t.timestamps
end
```

**Tests**:
- Model validations (name, RPII number, phone, address)
- Custom ID generation
- Logo attachment functionality
- Company statistics calculations
- User association

**Backwards Compatibility**: Full - no existing functionality affected

---

### Step 3: Add Photo Attachment Support to Equipment

**Objective**: Prepare Equipment model for Unit transformation by adding file attachments

**Changes**:
- Add `has_one_attached :photo` to Equipment model
- Update equipment controller to handle photo uploads
- Add photo parameter to strong params

**Files Affected**:
- `app/models/equipment.rb` (modified)
- `app/controllers/equipment_controller.rb` (modified)
- `spec/models/equipment_spec.rb` (modified)

**Migration**: None required (Active Storage already configured)

**Tests**:
- Photo attachment and retrieval
- Controller parameter handling
- Model photo presence validation (if required)

**Backwards Compatibility**: Full - photo is optional

---

## Phase 2: Core Model Expansion (Steps 4-6)

### Step 4: Expand Equipment Table with Unit Fields

**Objective**: Add all fields necessary to transform Equipment into Unit

**Changes**:
- Create migration to add Unit-specific fields to equipment table
- Maintain existing fields for backwards compatibility
- Add proper indexes and constraints

**Files Affected**:
- `db/migrate/xxx_add_unit_fields_to_equipment.rb` (new)

**Database Changes**:
```ruby
add_column :equipment, :description, :string
add_column :equipment, :unit_type, :string
add_column :equipment, :owner, :string
add_column :equipment, :serial_number, :string
add_column :equipment, :width, :decimal, precision: 8, scale: 2
add_column :equipment, :length, :decimal, precision: 8, scale: 2  
add_column :equipment, :height, :decimal, precision: 8, scale: 2
add_column :equipment, :notes, :text
add_column :equipment, :model, :string
add_column :equipment, :manufacture_date, :date
add_column :equipment, :condition, :string
# location already exists

add_index :equipment, :unit_type
add_index :equipment, [:manufacturer, :serial_number], unique: true
```

**Tests**:
- Migration runs successfully
- Existing Equipment records remain intact
- New fields accept appropriate values
- Indexes are created correctly

**Backwards Compatibility**: Full - existing Equipment functionality unchanged

---

### Step 5: Update Equipment Model to Include Unit Functionality

**Objective**: Transform Equipment model into Unit with advanced features while maintaining backwards compatibility

**Changes**:
- Add Unit-specific validations and methods
- Include CustomIdGenerator concern
- Add enum for unit_type
- Add dimension calculations and inspection tracking
- Maintain existing Equipment interface

**Files Affected**:
- `app/models/equipment.rb` (major modifications)
- `spec/models/equipment_spec.rb` (expanded tests)

**Key Features Added**:
- Unit type enum (bounce_house, slide, combo_unit, etc.)
- Dimension validations and calculations (area, volume)
- Serial number uniqueness within manufacturer
- Inspection status tracking (last inspection, overdue checks)
- Compliance status determination
- Inspection summary statistics

**Tests**:
- All existing Equipment functionality still works
- New Unit validations and methods
- Dimension calculations
- Inspection relationship methods
- Enum functionality
- Backwards compatibility with existing records

**Backwards Compatibility**: High - existing Equipment methods preserved, new functionality is additive

---

### Step 6: Expand Inspection Table with New Fields

**Objective**: Add comprehensive inspection fields to support advanced workflow

**Changes**:
- Create migration to add all new inspection fields
- Prepare for assessment relationships
- Add workflow status and audit fields

**Files Affected**:
- `db/migrate/xxx_add_inspection_fields.rb` (new)

**Database Changes**:
```ruby
add_column :inspections, :place_inspected, :string
add_column :inspections, :rpii_registration_number, :string
add_column :inspections, :unique_report_number, :string
add_column :inspections, :inspection_company_name, :string
add_column :inspections, :status, :string, default: 'draft'
add_column :inspections, :finalized_at, :datetime
add_reference :inspections, :finalized_by, foreign_key: { to_table: :users }
add_column :inspections, :general_notes, :text
add_column :inspections, :recommendations, :text
add_column :inspections, :weather_conditions, :string
add_column :inspections, :ambient_temperature, :decimal, precision: 5, scale: 2
add_column :inspections, :inspector_signature, :string
add_column :inspections, :signature_timestamp, :datetime
add_reference :inspections, :inspector_company, foreign_key: true, type: :string

# Update existing fields to match new system
rename_column :inspections, :inspection_date, :inspection_date # ensure date type
add_index :inspections, [:user_id, :unique_report_number], unique: true
add_index :inspections, :status
```

**Tests**:
- Migration runs successfully
- Existing Inspection records remain intact
- New fields accept appropriate values
- Foreign key relationships work correctly

**Backwards Compatibility**: Full - existing functionality preserved

---

## Phase 3: Advanced Features (Steps 7-9)

### Step 7: Create Assessment Models

**Objective**: Create all 7 specialized assessment models for detailed safety evaluations

**Changes**:
- Create migrations for each assessment table
- Create assessment models with specialized validations
- Implement completion tracking and safety check logic

**Files Affected**:
- `db/migrate/xxx_create_assessment_tables.rb` (new)
- `app/models/assessments/user_height_assessment.rb` (new)
- `app/models/assessments/slide_assessment.rb` (new)
- `app/models/assessments/structure_assessment.rb` (new)
- `app/models/assessments/anchorage_assessment.rb` (new)
- `app/models/assessments/materials_assessment.rb` (new)
- `app/models/assessments/fan_assessment.rb` (new)
- `app/models/assessments/enclosed_assessment.rb` (new)
- Corresponding spec files for each model

**Assessment Types**:
1. **UserHeightAssessment**: Age group and height compliance checks
2. **SlideAssessment**: Slide safety, runout distances, fall zones
3. **StructureAssessment**: Structural integrity, seams, air loss
4. **AnchorageAssessment**: Ground anchoring and stability
5. **MaterialsAssessment**: Material condition and safety
6. **FanAssessment**: Blower functionality and safety
7. **EnclosedAssessment**: Additional checks for enclosed units

**Common Features**:
- `complete?` method to check assessment completion
- `has_critical_failures?` for safety validation
- `safety_check_count` and `passed_checks_count` for statistics
- Specialized validation rules for each assessment type

**Tests**:
- Model validations for each assessment
- Completion detection logic
- Safety check calculations
- Critical failure detection
- Assessment-specific business rules

**Backwards Compatibility**: Full - assessments are new functionality

---

### Step 8: Update Inspection Model for Advanced Functionality

**Objective**: Transform Inspection model to support comprehensive workflow and assessment management

**Changes**:
- Add assessment relationships and nested attributes
- Implement workflow state machine
- Add audit logging and finalization process
- Include compliance determination logic

**Files Affected**:
- `app/models/inspection.rb` (major modifications)
- `spec/models/inspection_spec.rb` (expanded tests)

**Key Features Added**:
- Assessment associations (has_one for each assessment type)
- Status enum (draft, in_progress, completed, finalized)
- Unique report number generation
- Auto pass/fail determination based on assessments
- Inspection duplication for templates
- Mobile data synchronization support
- Comprehensive validation and audit logging

**Methods Added**:
- `can_be_finalized?` - checks if inspection is ready to finalize
- `finalize!(user)` - locks inspection and marks as complete
- `duplicate_for_user(user)` - creates copy for templating
- `validate_completeness` - returns list of incomplete sections
- `pass_fail_summary` - statistical overview of checks

**Tests**:
- Assessment relationship management
- Workflow state transitions
- Finalization process and restrictions
- Pass/fail determination logic
- Report number generation and uniqueness
- Audit logging functionality

**Backwards Compatibility**: Medium - existing basic inspection functionality preserved, but some internal logic changes

---

### Step 9: Create SafetyStandard Model

**Objective**: Implement safety standard validation and compliance checking

**Changes**:
- Create SafetyStandard model with validation methods
- Implement standard compliance checks used by assessments
- Add configuration for safety thresholds and requirements

**Files Affected**:
- `app/models/safety_standard.rb` (new)
- `spec/models/safety_standard_spec.rb` (new)

**Key Features**:
- Static validation methods for safety standards
- Threshold checking for measurements
- Age group and height requirements
- Material and structural safety standards
- Configurable safety parameters

**Validation Methods**:
- `valid_stitch_length?(length)` - seam integrity standards
- `valid_evacuation_time?(time)` - deflation time requirements
- `valid_pressure?(pressure)` - operating pressure standards
- `valid_fall_height?(height)` - maximum fall height limits
- `valid_age_group_height?(age_group, height)` - height restrictions

**Tests**:
- All validation methods with edge cases
- Standard compliance checking
- Threshold boundary testing
- Integration with assessment models

**Backwards Compatibility**: Full - new functionality only

---

## Phase 4: Testing & Controllers (Steps 10-12)

### Step 10: Comprehensive Model Tests

**Objective**: Ensure all new functionality is thoroughly tested

**Changes**:
- Expand existing model tests
- Add integration tests for complex workflows
- Test backwards compatibility scenarios
- Add performance tests for complex queries

**Files Affected**:
- All spec files under `spec/models/` (expanded)
- `spec/models/integration/` (new directory)

**Test Coverage Areas**:
- Model validations and relationships
- Custom ID generation across all models
- Assessment completion and scoring logic
- Inspection workflow state management
- Safety standard compliance checking
- Backwards compatibility with existing data
- Performance of complex association queries

**Test Types**:
- Unit tests for individual model methods
- Integration tests for cross-model functionality
- Factory setup for complex object creation
- Edge case and error condition testing

**Backwards Compatibility**: N/A - testing only

---

### Step 11: Update Equipment Controller for Units

**Objective**: Enhance equipment controller to handle Unit features while maintaining existing functionality

**Changes**:
- Add support for Unit-specific parameters
- Update search and filtering for new fields
- Add photo upload handling
- Enhance CSV export with new fields

**Files Affected**:
- `app/controllers/equipment_controller.rb` (modified)
- `spec/requests/equipment_spec.rb` (expanded)

**New Features**:
- Photo upload and display
- Unit type filtering
- Dimension-based searches
- Enhanced equipment statistics
- Compliance status display

**Parameter Updates**:
```ruby
def equipment_params
  params.require(:equipment).permit(:name, :location, :serial, :manufacturer,
    :description, :unit_type, :owner, :serial_number, :width, :length, 
    :height, :notes, :model, :manufacture_date, :condition, :photo)
end
```

**Tests**:
- All existing controller functionality preserved
- New parameter handling
- Photo upload processing
- Enhanced search and filtering
- CSV export with new fields

**Backwards Compatibility**: High - existing routes and basic functionality preserved

---

### Step 12: Update Inspection Controller for Enhanced Functionality

**Objective**: Enhance inspection controller to support advanced workflow and assessment management

**Changes**:
- Add assessment management endpoints
- Implement workflow state management
- Add finalization and approval processes
- Support for assessment completion tracking

**Files Affected**:
- `app/controllers/inspections_controller.rb` (major modifications)
- `spec/requests/inspections_spec.rb` (expanded)

**New Features**:
- Assessment section management
- Workflow status updates
- Inspection finalization process
- Progress tracking and completion validation
- Enhanced search and filtering by status

**New Routes/Actions**:
- Assessment updates (nested resource handling)
- Status transitions (draft → in_progress → completed → finalized)
- Completion validation
- Assessment progress reporting

**Tests**:
- Existing inspection CRUD operations
- Assessment management workflows
- Status transition validation
- Finalization process and restrictions
- Progress tracking accuracy

**Backwards Compatibility**: Medium - basic inspection functionality preserved, but some workflow changes required

## Progress Tracker

### Completed Steps ✅

1. **CustomIdGenerator Concern** - Added uppercase alphanumeric ID generation
2. **InspectorCompany Model** - Created with migration, validations, and 25 tests
3. **Equipment Photo Attachments** - Added ActiveStorage support
4. **Equipment Table Expansion** - Added all Unit fields via migration
5. **Equipment Model Enhancement** - Added Unit functionality while maintaining backwards compatibility (29 tests)
6. **Inspection Table Expansion** - Added comprehensive inspection workflow fields

### Current Status
- Database schema fully expanded for both Units and advanced Inspections
- Equipment model supports both legacy and Unit modes seamlessly  
- Ready for assessment models and advanced inspection functionality
- All Unit functionality tested and working

---

## Testing Strategy

### Per-Step Testing
Each step includes:
- **RSpec execution required after each step** - must pass all tests
- Model unit tests for new functionality
- Integration tests where applicable
- Backwards compatibility verification
- Migration rollback testing
- **New tests written for any new code before implementation**

### Comprehensive Testing
After completion:
- Full regression test suite
- Performance testing with large datasets
- Cross-browser compatibility (if applicable)
- Mobile responsiveness testing

### Test Data Management
- Factory setup for complex object hierarchies
- Seed data for development environment
- Test fixtures for assessment scenarios

## Risk Mitigation

### Database Safety
- All migrations include proper rollback methods
- Foreign key constraints prevent orphaned records
- Index creation for performance optimization

### Backwards Compatibility
- Existing model interfaces preserved where possible
- Graceful degradation for missing data
- Clear migration path for existing records

### Performance Considerations
- Efficient querying for complex associations
- Proper indexing for search functionality
- Lazy loading for assessment relationships

## Success Criteria

### Functional Requirements
- All existing testlog functionality preserved
- Complete RPII inspection workflow implemented
- Assessment management fully functional
- Compliance tracking and reporting working

### Technical Requirements
- All tests passing with good coverage
- No performance degradation
- Clean, maintainable code structure
- Proper error handling and validation

### Documentation
- Updated README with new functionality
- API documentation for new endpoints
- User guide for inspection workflow
- Developer documentation for maintenance

## Rollback Strategy

Each step can be rolled back independently:
1. **Database**: All migrations include `down` methods
2. **Code**: Git tags for each completed step
3. **Dependencies**: Gemfile changes tracked per step
4. **Configuration**: Environment-specific settings documented

## Timeline Estimation

- **Phase 1** (Foundation): 2-3 days
- **Phase 2** (Core Models): 3-4 days  
- **Phase 3** (Advanced Features): 4-5 days
- **Phase 4** (Testing & Controllers): 2-3 days

**Total Estimated Time**: 11-15 days

## Post-Migration Tasks

### Data Migration
- Script to populate new fields from existing data
- Assessment template creation
- User notification of new features

### Documentation Updates
- User manual updates
- API documentation refresh
- Deployment guide updates

### Training and Support
- User training materials
- Support documentation
- FAQ for new features

---

*This migration plan provides a comprehensive roadmap for transforming the basic testlog application into a full-featured RPII inspection system while maintaining backwards compatibility and ensuring thorough testing at each step.*