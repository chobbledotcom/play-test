# RPII Utility - Comprehensive Technical Specification

## Project Overview

**RPII Utility** is a Windows Forms application developed in C# (.NET 9.0) for conducting and managing RPII (Recreational Product Inspection Institute) safety inspections of inflatable recreational products such as bounce houses, slides, and similar equipment.

### Key Technologies
- **Framework**: .NET 9.0 Windows Forms
- **Database**: SQLite 3 (System.Data.SQLite v1.0.119)
- **PDF Generation**: PDFsharp v6.2.0-preview-3
- **Platform Support**: Windows (AnyCPU, x86)

## Database Model

### Primary Table: `Inspections`

The application uses a single comprehensive SQLite table to store all inspection data:

```sql
CREATE TABLE IF NOT EXISTS Inspections (
    -- Primary Key & Global Details
    TagID INTEGER PRIMARY KEY,
    inspectionCompany TEXT,
    inspectionDate TEXT,
    RPIIRegNum TEXT,
    placeInspected TEXT,
    
    -- Unit Details
    unitDescription TEXT,
    unitManufacturer TEXT,
    unitWidth REAL,
    unitLength REAL,
    unitHeight REAL,
    serial TEXT,
    unitType TEXT,
    unitOwner TEXT,
    image TEXT,
    
    -- User Height/Count Measurements
    containingWallHeight REAL,
    containingWallHeightComment TEXT,
    platformHeight REAL,
    platformHeightComment TEXT,
    slideBarrierHeight REAL,
    slideBarrierHeightComment TEXT,
    remainingSlideWallHeight REAL,
    remainingSlideWallHeightComment TEXT,
    permanentRoof INTEGER,
    permanentRoofComment TEXT,
    userHeight REAL,
    userHeightComment TEXT,
    playAreaLength REAL,
    playAreaLengthComment TEXT,
    playAreaWidth REAL,
    playAreaWidthComment TEXT,
    negAdjustment REAL,
    negAdjustmentComment TEXT,
    usersat1000mm INTEGER,
    usersat1200mm INTEGER,
    usersat1500mm INTEGER,
    usersat1800mm INTEGER,
    
    -- Slide Measurements
    slidePlatformHeight REAL,
    slidePlatformHeightComment TEXT,
    slideWallHeight REAL,
    slideWallHeightComment TEXT,
    slideFirstMetreHeight REAL,
    slideFirstMetreHeightComment TEXT,
    slideBeyondFirstMetreHeight REAL,
    slideBeyondFirstMetreHeightComment TEXT,
    slidePermanentRoof INTEGER,
    slidePermanentRoofComment TEXT,
    clamberNettingPass INTEGER,
    clamberNettingComment TEXT,
    runoutValue REAL,
    runoutPass INTEGER,
    runoutComment TEXT,
    slipSheetPass INTEGER,
    slipSheetComment TEXT,
    
    -- Structure Inspection Fields
    seamIntegrityPass INTEGER,
    seamIntegrityComment TEXT,
    lockStitchPass INTEGER,
    lockStitchComment TEXT,
    stitchLength INTEGER,
    stitchLengthPass INTEGER,
    stitchLengthComment TEXT,
    airLossPass INTEGER,
    airLossComment TEXT,
    straightWallsPass INTEGER,
    straightWallsComment TEXT,
    sharpEdgesPass INTEGER,
    sharpEdgesComment TEXT,
    blowerTubeLength REAL,
    blowerTubeLengthPass INTEGER,
    blowerTubeLengthComment TEXT,
    unitStablePass INTEGER,
    unitStableComment TEXT,
    evacTime INTEGER,
    evacTimePass INTEGER,
    evacTimeComment TEXT,
    stepSizeValue REAL,
    stepSizePass INTEGER,
    stepSizeComment TEXT,
    falloffHeightValue REAL,
    falloffHeightPass INTEGER,
    falloffHeightComment TEXT,
    unitPressureValue REAL,
    unitPressurePass INTEGER,
    unitPressureComment TEXT,
    troughDepthValue REAL,
    troughWidthValue REAL,
    troughPass INTEGER,
    troughComment TEXT,
    entrapPass INTEGER,
    entrapComment TEXT,
    markingsPass INTEGER,
    markingsComment TEXT,
    groundingPass INTEGER,
    groundingComment TEXT,
    
    -- Anchorage System
    numLowAnchors INTEGER,
    numHighAnchors INTEGER,
    numAnchorsPass INTEGER,
    numAnchorsComment TEXT,
    anchorAccessoriesPass INTEGER,
    anchorAccessoriesComment TEXT,
    anchorDegreePass INTEGER,
    anchorDegreeComment TEXT,
    anchorTypePass INTEGER,
    anchorTypeComment TEXT,
    pullStrengthPass INTEGER,
    pullStrengthComment TEXT,
    
    -- Totally Enclosed Equipment
    exitNumber INTEGER,
    exitNumberPass INTEGER,
    exitNumberComment TEXT,
    exitVisiblePass INTEGER,
    exitVisibleComment TEXT,
    
    -- Materials Inspection
    ropeSize INTEGER,
    ropeSizePass INTEGER,
    ropeSizeComment TEXT,
    clamberPass INTEGER,
    clamberComment TEXT,
    retentionNettingPass INTEGER,
    retentionNettingComment TEXT,
    zipsPass INTEGER,
    zipsComment TEXT,
    windowsPass INTEGER,
    windowsComment TEXT,
    artworkPass INTEGER,
    artworkComment TEXT,
    threadPass INTEGER,
    threadComment TEXT,
    fabricPass INTEGER,
    fabricComment TEXT,
    fireRetardentPass INTEGER,
    fireRetardentComment TEXT,
    
    -- Fan/Blower System
    fanSizeComment TEXT,
    blowerFlapPass INTEGER,
    blowerFlapComment TEXT,
    blowerFingerPass INTEGER,
    blowerFingerComment TEXT,
    patPass INTEGER,
    patComment TEXT,
    blowerVisualPass INTEGER,
    blowerVisualComment TEXT,
    blowerSerial TEXT,
    
    -- Risk Assessment
    riskAssessment TEXT,
    
    -- Final Inspection Result
    passed INTEGER,
    Testimony TEXT
);
```

### Field Types and Validation

#### INTEGER Fields
- **Pass/Fail Fields**: Store as 0 (fail) or 1 (pass)
- **Count Fields**: Non-negative integers
- **Boolean Fields**: 0 (false) or 1 (true)

#### REAL Fields
- **Measurement Fields**: Decimal values for dimensions, heights, pressures
- **Precision**: Standard floating-point precision
- **Units**: Implied by field context (mm, meters, etc.)

#### TEXT Fields
- **Comment Fields**: Free-form text for inspection notes
- **Identifier Fields**: Serial numbers, registration numbers
- **Description Fields**: Equipment descriptions and details

## Application Architecture

### Main Form Structure

The application consists of a single main form (`Form1`) with a tabbed interface containing:

1. **Main Tab** - Global inspection details and inspector information
2. **Unit Details Tab** - Equipment specifications and photo
3. **User Height Tab** - Height measurements and user capacity
4. **Slide Tab** - Slide-specific measurements
5. **Structure Tab** - Structural integrity checks
6. **Structure2 Tab** - Additional structural assessments
7. **Anchorage Tab** - Anchoring system inspection
8. **Enclosed Tab** - Totally enclosed equipment checks
9. **Materials Tab** - Material quality assessments
10. **Fan Tab** - Blower/fan system inspection
11. **Risk Assessment Tab** - Overall risk evaluation

### Core Functionality

#### Database Operations
- **Location**: Form1.cs:71-87 (`CreateConnection()`)
- **Table Creation**: Form1.cs:96-278 (`CreateTable()`)
- **Connection String**: `"Data Source=RPIIInspections.db; Version = 3; New = True; Compress = True;"`

#### Photo Management
- **Upload**: Form1.cs:27-51 (`uploadPhotoBtn_Click`, `choosePhoto()`)
- **Logo Selection**: Form1.cs:53-67 (`chooseLogo()`)
- **Storage**: File paths stored as TEXT in `image` field

#### PDF Report Generation
- **Technology**: PDFsharp library
- **Trigger**: Form1.cs:774 (`createPDFBtn_Click`)
- **Content**: Complete inspection report with measurements and photos

## User Interface Components

### Button Events

| Button | Event Handler Location | Functionality |
|--------|----------------------|---------------|
| Upload Photo | Form1.cs:27 | Opens file dialog for unit photo selection |
| Select Logo | Form1.cs:1650 | Opens file dialog for inspector logo |
| Save | Form1.cs:764 | Saves current inspection to database |
| New | Form1.cs:769 | Clears form for new inspection |
| Create PDF | Form1.cs:774 | Generates PDF report |
| Load All Records | Form1.cs:1600 | Displays all inspections |
| Clear Records | Form1.cs:1605 | Clears displayed records |
| Search by Owner | Form1.cs:1610 | Searches by unit owner |
| Search by Report Number | Form1.cs:1622 | Searches by unique report ID |

### Input Controls

#### Global Details
- **Inspection Company**: TextBox (`InspectionCompName`)
- **Inspection Date**: DateTimePicker (`datePicker`)
- **RPII Registration**: TextBox (`rpiiReg`)
- **Location**: TextBox (`inspectionLocation`)
- **Pass/Fail**: RadioButton (`passedRadio`/`failedRadio`)
- **Testimony**: RichTextBox (`testimony`)

#### Unit Details
- **Description**: TextBox (`unitDescriptionText`)
- **Manufacturer**: TextBox (`ManufacturerText`)
- **Dimensions**: NumericUpDown controls for width, length, height
- **Serial Number**: TextBox (`serialText`)
- **Unit Type**: TextBox (`unitTypeText`)
- **Owner**: TextBox (`unitOwnerText`)
- **Photo**: PictureBox (`unitPic`)

#### Measurement Controls
- **Height Values**: NumericUpDown controls with decimal precision
- **Pass/Fail Checks**: CheckBox or RadioButton controls
- **Comments**: TextBox controls for inspector notes
- **User Counts**: NumericUpDown for user capacity at different heights

### Validation Rules

The application implements validation through:
- **Required Fields**: Enforced during save operations
- **Numeric Ranges**: Implicit through NumericUpDown control limits
- **Data Types**: Enforced by control types and database schema
- **File Validation**: Image file type checking in photo upload

## Resources

### Embedded Images
- **LOGO**: Company/inspector logo (LOGO.png)
- **No_Image_Available**: Placeholder for missing unit photos
- **slide-calc-1** & **slide-calc-2**: Reference images for calculations

### File Management
- **Database File**: `RPIIInspections.db` (created in application directory)
- **Photo Storage**: File paths stored in database, actual files remain in original locations
- **PDF Output**: Generated on-demand with timestamped filenames

## Dependencies

### NuGet Packages
1. **PDFsharp v6.2.0-preview-3**
   - Purpose: PDF report generation
   - Features: Drawing, layout, font management

2. **System.Data.SQLite v1.0.119**
   - Purpose: SQLite database operations
   - Features: ADO.NET provider for SQLite

### Framework Features
- **Windows Forms**: UI framework
- **System.Drawing**: Image handling and manipulation
- **System.IO**: File operations
- **System.Data**: Database abstractions

## Data Integrity

### Primary Key
- **TagID**: Auto-incrementing integer primary key
- **Uniqueness**: Ensures each inspection has unique identifier

### Referential Integrity
- Single-table design eliminates foreign key constraints
- Data consistency maintained through application logic

### Backup and Recovery
- SQLite database file can be copied for backup
- No built-in backup mechanism in application
- Database file location: Application execution directory

## Security Considerations

### Data Storage
- Local SQLite database (no network exposure)
- File system permissions control access
- No encryption implemented

### Input Validation
- Basic type checking through UI controls
- SQL injection protection through parameterized queries
- File type validation for image uploads

This specification covers the core data model and architecture. Additional documentation for UI workflows, validation rules, and business logic can be found in supplementary files.