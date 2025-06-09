# Views Architecture Plan

This document outlines the comprehensive view structure needed for the TestLog inspection application based on the model analysis and workflow requirements.

## **Overview**

The application requires a sophisticated view structure to handle:

- Multi-stage inspection workflows with 7 different assessment types
- Equipment/Unit management with compliance tracking
- Inspector company credential management
- Professional safety documentation and certification

## **Core Entity Management Views**

### **InspectorCompany Views** (Priority 1 - Missing Controller)

**Directory: `/app/views/inspector_companies/`**

- `index.html.erb` - List all inspector companies with search/filter capabilities

  - Search by company name, RPII registration number
  - Filter by verification status (verified/unverified)
  - Display company cards with key info
  - Admin controls for managing companies

- `show.html.erb` - Company profile page

  - Company details and contact information
  - RPII verification status and credentials
  - Statistics (number of inspections performed)
  - List of associated inspectors/users
  - Company branding/logo display

- `new.html.erb` - Create new inspector company form

  - Company registration workflow
  - RPII credential input
  - Address and contact details
  - Initial verification status setting

- `edit.html.erb` - Edit company details

  - Update company information
  - Manage RPII verification status
  - Update contact details and branding
  - Admin-only fields for verification management

- `_form.html.erb` - Shared form partial

  - Company name and registration fields
  - RPII registration number with validation
  - Contact information (email, phone, address)
  - Verification status controls
  - Notes field for admin use

- `_company_card.html.erb` - Company display card partial
  - Company name and RPII status
  - Verification badge/indicator
  - Contact information summary
  - Quick action buttons (view, edit)

### **Enhanced Equipment Views**

**Directory: `/app/views/equipment/` (extending existing)**

**New views needed:**

- `compliance_dashboard.html.erb` - Equipment compliance overview

  - Visual compliance status indicators
  - Overdue inspection alerts
  - Equipment categorized by compliance status
  - Quick action buttons for scheduling inspections

- `inspection_schedule.html.erb` - Schedule upcoming inspections

  - Calendar view of scheduled inspections
  - Equipment due for inspection
  - Inspector assignment interface
  - Scheduling conflict detection

- `_unit_specifications.html.erb` - Detailed unit specifications partial

  - Physical dimensions (length, width, height)
  - Capacity calculations by age group
  - Unit type and classification
  - Manufacturer specifications

- `_compliance_status.html.erb` - Visual compliance indicators partial
  - Color-coded status badges
  - Last inspection date
  - Next inspection due date
  - Compliance percentage/score

## **Multi-Stage Inspection Workflow Views**

### **Assessment Views**

**Directory: `/app/views/inspections/assessments/`**

Each assessment type requires dedicated forms with specialized validation:

- `user_height_assessment.html.erb` - Height and capacity calculations

  - User height input and validation
  - Containing wall height requirements
  - Capacity calculations by age group
  - Safety threshold checks

- `structure_assessment.html.erb` - Structure integrity assessment

  - Pass/fail checklist for structural elements
  - Measurement fields for critical dimensions
  - Stitch length and air pressure testing
  - Evacuation time validation

- `slide_assessment.html.erb` - Slide safety requirements

  - Platform height measurements
  - Runout length calculations
  - Wall height requirements
  - Safety compliance checks

- `materials_assessment.html.erb` - Material compliance testing

  - Fabric tensile strength checks
  - Thread and rope specifications
  - Fire retardancy compliance
  - Material condition assessment

- `fan_assessment.html.erb` - Blower and electrical testing

  - Electrical safety (PAT testing)
  - Blower specifications and performance
  - Grounding and safety checks
  - Operating pressure validation

- `enclosed_assessment.html.erb` - Enclosed space safety

  - Ventilation and air quality checks
  - Emergency exit requirements
  - Occupancy limit calculations
  - Environmental safety factors

- `anchorage_assessment.html.erb` - Anchoring system validation
  - Anchor point calculations
  - Pull strength testing
  - Angle and positioning checks
  - Ground condition assessment

### **Inspection Workflow Views**

**Directory: `/app/views/inspections/workflow/`**

- `inspection_wizard.html.erb` - Multi-step inspection process

  - Progress indicator showing completion status
  - Navigation between assessment stages
  - Validation feedback for incomplete sections
  - Save and resume functionality

- `assessment_dashboard.html.erb` - Overview of all assessments

  - Status grid showing all 7 assessment types
  - Completion percentages
  - Priority indicators for critical items
  - Quick access to incomplete assessments

- `draft_review.html.erb` - Review before finalizing

  - Summary of all assessment results
  - Validation checklist
  - Error and warning indicators
  - Final review before approval

- `finalization.html.erb` - Final approval and certification

  - Inspector signature interface
  - Final certification generation
  - PDF report creation
  - QR code generation for verification

- `_progress_indicator.html.erb` - Visual progress partial

  - Step-by-step progress visualization
  - Completed/pending/error status indicators
  - Navigation between workflow stages

- `_assessment_summary.html.erb` - Assessment summary partial
  - Key results from each assessment
  - Pass/fail status for critical items
  - Summary of measurements and calculations

## **Specialized Functionality Views**

### **Compliance & Reporting**

**Directory: `/app/views/compliance/`**

- `compliance_dashboard.html.erb` - System-wide compliance overview

  - Overall compliance statistics
  - Equipment status breakdown
  - Trending and analytics
  - Alert management

- `overdue_inspections.html.erb` - Equipment needing attention

  - List of overdue equipment
  - Criticality assessment
  - Inspector assignment interface
  - Bulk action capabilities

- `safety_alerts.html.erb` - Critical safety notifications

  - Active safety alerts
  - Equipment with safety issues
  - Notification management
  - Escalation procedures

- `reports.html.erb` - Generated reports and QR codes
  - Report gallery
  - QR code management
  - Download and sharing options
  - Report validation interface

### **Admin & User Management**

**Directory: `/app/views/admin/` (extending existing user views)**

- `system_dashboard.html.erb` - Admin system overview

  - System health indicators
  - User activity summary
  - Equipment and inspection statistics
  - System alerts and notifications

- `job_monitoring.html.erb` - Background job status

  - Job queue status
  - Failed job management
  - Performance monitoring
  - System maintenance controls

- `user_activity.html.erb` - User activity tracking
  - User login and activity logs
  - Inspection activity by user
  - Performance metrics
  - Access control management

### **Mobile/Offline Views**

**Directory: `/app/views/mobile/`**

- `mobile_inspection.html.erb` - Mobile-optimized inspection form

  - Touch-friendly interface
  - Camera integration for photos
  - GPS location capture
  - Offline data storage

- `offline_sync.html.erb` - Sync status and queue management

  - Synchronization status indicators
  - Offline queue management
  - Conflict resolution interface
  - Data integrity checks

- `field_checklist.html.erb` - Printable field inspection checklist
  - Printer-friendly format
  - Checklist items for field use
  - QR codes for digital integration
  - Emergency contact information

## **Shared Partials**

### **Assessment Components**

**Directory: `/app/views/shared/assessments/`**

- `_height_form.html.erb` - Height assessment form components
- `_slide_form.html.erb` - Slide assessment form components
- `_structure_form.html.erb` - Structure assessment form components
- `_anchorage_form.html.erb` - Anchorage assessment form components
- `_materials_form.html.erb` - Materials assessment form components
- `_fan_form.html.erb` - Fan assessment form components
- `_enclosed_form.html.erb` - Enclosed assessment form components
- `_safety_check_item.html.erb` - Reusable safety check component
- `_measurement_field.html.erb` - Standardized measurement input
- `_pass_fail_field.html.erb` - Pass/fail selection component
- `_compliance_indicator.html.erb` - Visual compliance status

### **Navigation & Layout**

**Directory: `/app/views/shared/`**

- `_assessment_navigation.html.erb` - Navigation between assessments
- `_workflow_breadcrumbs.html.erb` - Breadcrumb navigation
- `_status_badges.html.erb` - Reusable status indicators
- `_action_buttons.html.erb` - Standardized action buttons

## **Implementation Priority**

### **Phase 1: Core Functionality**

1. **InspectorCompany** CRUD views (missing controller)
2. **Enhanced Equipment** views for compliance tracking
3. **Basic Assessment** workflow views

### **Phase 2: Advanced Workflow**

4. **Assessment Dashboard** and navigation
5. **Inspection Workflow** management
6. **Compliance and Reporting** views

### **Phase 3: Enhanced Features**

7. **Admin and User Management** enhancements
8. **Mobile/PWA** views for field use
9. **Advanced Reporting** and analytics

## **Key Workflow Requirements**

The inspection process follows this pattern:

1. **Draft** → Create basic inspection record with equipment association
2. **Assessment Stages** → Complete 7 different assessment types with validation
3. **Review** → Validate all requirements met and resolve any issues
4. **Finalization** → Official approval with inspector signature and certification
5. **Documentation** → PDF generation, QR code creation, and report issuance

## **Technical Considerations**

- **Progressive Web App (PWA)** capabilities for offline field use
- **Responsive design** for mobile and tablet devices
- **Accessibility compliance** for professional use
- **Print-friendly** formats for field checklists and reports
- **Real-time validation** for safety calculations and requirements
- **Audit trail** capabilities for all changes and approvals

## **Styling Guidelines**

**IMPORTANT: All views should use simple, semantic HTML with NO custom CSS classes or styling.**

- Use basic HTML elements: `<p>`, `<h1>`, `<h2>`, `<table>`, `<form>`, `<label>`, `<input>`, `<select>`, `<a>`
- Rely on browser default styling only
- Use `<table>` for tabular data display
- Use standard form elements without custom classes
- Use semantic HTML structure for accessibility
- Keep markup clean and minimal - focus on functionality over appearance

The styling and CSS will be handled separately. These views should be purely functional with semantic HTML structure.

This comprehensive view structure supports a professional safety inspection system with detailed compliance tracking, multi-stage workflows, and robust documentation capabilities.
