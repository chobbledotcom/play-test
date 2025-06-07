# RPII Utility - Rails Application Architecture

## Overview

This document outlines the complete Rails architecture for migrating the Windows Forms RPII Utility to a modern web application. The design normalizes the original 142-field single table into a proper relational structure while maintaining all functionality and business rules.

## Directory Structure

```
rails/
├── app/
│   ├── controllers/
│   │   ├── inspections_controller.rb           # Primary inspection management
│   │   ├── inspection_reports_controller.rb # PDF generation
│   │   ├── units_controller.rb                 # Equipment library
│   │   ├── inspector_companies_controller.rb   # Company profiles
│   │   ├── safety_standards_controller.rb      # Reference tools
│   │   ├── reports_controller.rb               # Analytics & reporting
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── inspections_controller.rb   # Mobile API
│   │   │       └── units_controller.rb         # Equipment API
│   │   └── admin/
│   │       ├── users_controller.rb             # User management
│   │       └── system_controller.rb            # System admin
│   └── models/
│       ├── user.rb                             # Inspector accounts
│       ├── inspection.rb                       # Main inspection record
│       ├── unit.rb                             # Equipment being inspected
│       ├── inspector_company.rb                # Company credentials
│       ├── safety_standard.rb                  # Business rules engine
│       └── assessments/
│           └── user_height_assessment.rb       # Height/capacity assessment
└── RAILS_ARCHITECTURE.md                       # This file
```

## Database Architecture

### Normalized Design vs Original

**Original Windows Forms**: Single table with 142 fields
**New Rails Design**: Normalized relational structure

### Core Models

#### 1. User (Inspector Authentication)

- **Purpose**: Inspector accounts and RPII credentials
- **Key Fields**: email, rpii_registration_number, rpii_verified
- **Relationships**: has_many inspections, units, inspector_companies

#### 2. Inspection (Main Record)

- **Purpose**: Primary inspection workflow and status
- **Key Fields**: unique_report_number, status, passed, inspection_date
- **Relationships**: belongs_to user, unit, inspector_company
- **Associations**: has_one for each assessment type

#### 3. Unit (Equipment Library)

- **Purpose**: Reusable equipment records with inspection history
- **Key Fields**: description, manufacturer, dimensions, serial_number
- **Relationships**: belongs_to user, has_many inspections
- **Features**: Photo attachments, compliance tracking

#### 4. InspectorCompany (Credentials & Branding)

- **Purpose**: Company profiles with RPII verification
- **Key Fields**: name, rpii_registration_number, logo
- **Relationships**: belongs_to user, has_many inspections

#### 5. Assessment Models (Normalized Data)

- **UserHeightAssessment**: Height measurements, user capacity
- **SlideAssessment**: Slide-specific safety checks
- **StructureAssessment**: Structural integrity
- **AnchorageAssessment**: Anchoring system
- **MaterialsAssessment**: Material compliance
- **FanAssessment**: Electrical/blower safety
- **EnclosedAssessment**: Totally enclosed equipment (conditional)

### Assessment Normalization Benefits

**Before**: 142 fields in single table
**After**: Logical groupings across related tables

Benefits:

- **Maintainability**: Easier to modify specific assessment categories
- **Performance**: Only load relevant assessment data
- **Flexibility**: Add new assessment types without table changes
- **Validation**: Category-specific business rules
- **Reporting**: Better analytics on assessment categories

## Controller Architecture

### Public Controllers

#### InspectionsController

- **Primary workflow**: Create, edit, complete inspections
- **Tabbed interface**: Matches original Windows Forms layout
- **Features**: Auto-save, validation, status management
- **Security**: RPII credential validation

#### InspectionReportsController

- **PDF generation**: Recreates original report layout
- **Email delivery**: Send reports to stakeholders
- **Format**: Maintains original single-page A4 format

#### UnitsController

- **Equipment library**: Manage reusable equipment records
- **History tracking**: View inspection history per unit
- **Search**: Find equipment by various criteria

#### SafetyStandardsController

- **Reference tools**: Interactive calculation tools
- **Standards display**: EN 14960:2019 requirements
- **Calculators**: Height, anchor, runout calculations

### API Controllers

#### Api::V1::InspectionsController

- **Mobile support**: Offline inspection capability
- **Sync functionality**: Handle mobile data synchronization
- **JSON API**: RESTful endpoints for mobile app

### Admin Controllers

#### Admin::UsersController

- **User management**: Verify RPII credentials
- **Statistics**: Inspector performance analytics

#### Admin::SystemController

- **System monitoring**: Health checks, error logs
- **Backup management**: Database backup controls

## Business Logic Layer

### SafetyStandard Model

- **Calculation engine**: All safety formulas and thresholds
- **Validation rules**: EN 14960:2019 compliance checks
- **Constants**: Height categories, safety thresholds
- **Methods**: Dynamic safety calculations

#### Key Calculations

- **Height requirements**: Containing wall calculations
- **Runout requirements**: Slide safety distances
- **Anchor calculations**: Required anchor points
- **User capacity**: Age-based capacity limits

### Assessment Validation

- **Completion tracking**: Percentage complete per section
- **Safety checks**: Pass/fail determination logic
- **Critical failures**: Identify safety-critical issues
- **Business rules**: Enforce EN 14960:2019 standards

## State Management

### Inspection Workflow

1. **Draft**: Initial creation, fields being filled
2. **In Progress**: Active completion of assessments
3. **Completed**: All assessments done, pending finalization
4. **Finalized**: Locked, report generated

### Status Transitions

- **Auto-progression**: Based on assessment completion
- **Manual finalization**: Inspector confirms completion
- **Audit trail**: Track all status changes

## Security Features

### Authentication & Authorization

- **Devise integration**: Standard Rails authentication
- **RPII verification**: Required for inspector actions
- **Role-based access**: Admin vs Inspector permissions

### Data Protection

- **Parameterized queries**: Prevent SQL injection
- **Input validation**: Comprehensive field validation
- **File upload security**: Secure image handling
- **Audit logging**: Track all inspection changes

## Integration Features

### Mobile Support

- **API endpoints**: RESTful JSON API
- **Offline capability**: Local storage sync
- **Photo uploads**: Mobile camera integration

### Reporting & Analytics

- **Pass/fail statistics**: Compliance tracking
- **Equipment performance**: Unit history analysis
- **Trend analysis**: Compliance over time
- **Export capabilities**: CSV, Excel formats

### PDF Generation

- **Report recreation**: Exact Windows Forms layout
- **Image handling**: Logo and photo integration
- **Email delivery**: Automated report distribution

## Migration Strategy

### Data Migration

1. **Extract**: Parse original 142-field records
2. **Transform**: Split into normalized structure
3. **Load**: Populate new relational tables
4. **Validate**: Ensure data integrity

### Workflow Migration

1. **UI recreation**: Match original tabbed interface
2. **Business rules**: Implement all validation logic
3. **PDF layout**: Recreate exact report format
4. **Testing**: Validate against original functionality

## Enhancement Opportunities

### Beyond Original Functionality

- **Equipment library**: Reusable unit records
- **History tracking**: Complete inspection timeline
- **Mobile app**: Field inspection capability
- **Advanced reporting**: Analytics dashboard
- **Multi-company**: Multiple inspector companies per user
- **Audit trails**: Complete change tracking
- **Automated reminders**: Inspection due dates
- **Compliance dashboard**: Real-time status overview

### Performance Improvements

- **Database optimization**: Proper indexing strategy
- **Caching**: Redis for frequently accessed data
- **Background jobs**: Async PDF generation
- **CDN integration**: Optimized image delivery

This architecture provides a solid foundation for migrating the Windows Forms application while adding modern web capabilities and improving maintainability through proper database normalization.
