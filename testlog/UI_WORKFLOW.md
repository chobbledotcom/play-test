# RPII Utility - User Interface Workflow Documentation

## Application Overview

The RPII Utility uses a Windows Forms interface with a **three-level tab structure**:
1. **Main Tabs**: Inspection, Useful Calculations, Records
2. **Inspection Sub-tabs**: 10 inspection categories
3. **Control Groups**: Organized input sections within each tab

## Main Tab Structure

### 1. Inspection Tab (`tabPage1`)
**Purpose**: Primary inspection workflow
**Contains**: Global inspection details and nested inspection tabs

#### Global Controls (Main Inspection Tab)
| Control | Type | Purpose | Default Value |
|---------|------|---------|---------------|
| `InspectionCompName` | TextBox | Inspector company name | - |
| `uniquereportNum` | TextBox | Unique report identifier | - |
| `datePicker` | DateTimePicker | Inspection date | Current date |
| `rpiiReg` | TextBox | RPII registration number | - |
| `inspectionLocation` | TextBox | Place of inspection | "On site" |
| `passedRadio` / `failedRadio` | RadioButton | Final inspection result | - |
| `testimony` | RichTextBox | Inspector testimony | Default compliance statement |
| `selectLogoBtn` | Button | Import inspector logo | - |
| `inspectorsLogo` | PictureBox | Display inspector logo | - |

#### Inspection Sub-Tabs Structure

##### A. Unit Details Tab (`UnitDetailsTab`)
**Purpose**: Equipment identification and specifications

| Control | Type | Purpose | Validation |
|---------|------|---------|------------|
| `unitDescriptionText` | TextBox | Equipment description | Required |
| `ManufacturerText` | TextBox | Equipment manufacturer | Required |
| `unitWidthNum` | NumericUpDown | Width in meters | 1 decimal place, default 1.0 |
| `unitLengthNum` | NumericUpDown | Length in meters | 1 decimal place, default 1.0 |
| `unitHeightNum` | NumericUpDown | Height in meters | 1 decimal place, default 1.0 |
| `serialText` | TextBox | Serial number | Required |
| `unitTypeText` | TextBox | Equipment type | Required |
| `unitOwnerText` | TextBox | Equipment owner | Required |
| `uploadPhotoBtn` | Button | Import equipment photo | - |
| `unitPic` | PictureBox | Display equipment photo | - |

##### B. User Height/Count Tab (`UserHeightTab`)
**Purpose**: User capacity and height measurements

**Height Measurements (2 decimal places)**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `containingWallHeightValue` | Containing wall height | "Lowest wall height taken from adjacent platform" |
| `platformHeightValue` | Tallest platform height | - |
| `slidebarrierHeightValue` | First metre slide wall height | - |
| `remainingSlideWallHeightValue` | Remaining slide wall height | Default: 0.06m |
| `userHeight` | Tallest user height | "Calculated using lowest containing wall height..." |

**Play Area Measurements**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `playAreaLengthValue` | Internal play area length | - |
| `playAreaWidthValue` | Internal play area width | - |
| `negAdjustmentValue` | Area reduction for obstacles | "Approx square metre taken by obstacles..." |

**User Capacity Controls**:
| Control | Purpose |
|---------|---------|
| `usersat1000mm` | Number of users @ 1.0m height |
| `usersat1200mm` | Number of users @ 1.2m height |
| `usersat1500mm` | Number of users @ 1.5m height |
| `usersat1800mm` | Number of users @ 1.8m height |

**Special Controls**:
| Control | Type | Purpose | Synchronization |
|---------|------|---------|----------------|
| `permanentRoofChecked` | CheckBox | Permanent roof fitted | Syncs with slide tab |

##### C. Slide Tab (`SlideTab`)
**Purpose**: Slide-specific measurements and safety checks

**Slide Measurements**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `slidePlatformHeightValue` | Slide platform height | - |
| `slideWallHeightValue` | Slide wall height | "Lowest wall height taken from the slide platform..." |
| `slidefirstmetreHeightValue` | First metre wall height | - |
| `beyondfirstmetreHeightValue` | Beyond first metre height | - |
| `runoutValue` | Slide run-out distance | - |

**Slide Safety Checks**:
| Control | Type | Purpose | Default Comment |
|---------|------|---------|-----------------|
| `slidePermRoofedCheck` | CheckBox | Permanent roof on slide | Syncs with user height tab |
| `clamberNettingPassFail` | CheckBox | Steps/clamber netting pass | "Not monofilament, no entrapment..." |
| `runOutPassFail` | CheckBox | Run-out compliance | "Slide Run-out is at least 50% of slide platform height" |
| `slipsheetPassFail` | CheckBox | Slip sheet integrity | "Slip sheet has no tears, causes no entrapment..." |

##### D. Structure Tab (`StructureTab`)
**Purpose**: Structural integrity and safety checks

**Pass/Fail Safety Checks**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `seamIntegrityPassFail` | Seam integrity | "Secure and no loose stitching" |
| `lockstitchPassFail` | Lock stitching quality | "Lock stitching used" |
| `stitchLengthPassFail` | Stitch length compliance | "Stitching between 3mm - 8mm" |
| `airLossPassFail` | Air retention | "No significant air loss or holes" |
| `wallStraightPassFail` | Wall verticality | "Walls Vertical and gradient no greater than +-5%" |
| `sharpEdgesPassFail` | Sharp edge safety | "No sharp or pointed edges" |
| `tubeDistancePassFail` | Blower tube distance | "Inflate blower tube is at least 1.2m from edge..." |
| `stablePassFail` | Unit stability | "Unit is stable" |
| `evacTimePassFail` | Evacuation time | "Evacuation time sufficient for intended users..." |

**Measurement Controls**:
| Control | Purpose | Unit |
|---------|---------|------|
| `stitchLengthValue` | Stitch length | mm |
| `tubeDistanceValue` | Blower tube distance | meters (2 decimal) |
| `evacTime` | Evacuation time | seconds |

##### E. Structure Cont. Tab (`Structure2Tab`)
**Purpose**: Additional structural assessments

**Measurement and Safety Checks**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `stepSizePassFail` | Step/ramp size | "Step/Ramp tread depth is equal to or more then 1.5 times..." |
| `falloffHeightPassFail` | Critical fall-off height | "Critical Fall Off Height is a max of 600mm/0.6m" |
| `pressurePassFail` | Unit pressure | "Pressure is a minimum of 1.0 KPA" |
| `troughPassFail` | Trough dimensions | "Trough Depth is no more than one third (1/3)..." |
| `entrapPassFail` | Entrapment check | "No entrapments" |
| `markingsPassFail` | Equipment markings | "Blower, User Height, Max Users, Unique ID..." |
| `groundingPassFail` | Grounding test | "25kg @ 1m, 35kg @ 1.2m, 65kg @ 1.5m and 85kg @ 1.8m" |

**Trough Measurement Group**:
| Control | Purpose | Unit |
|---------|---------|------|
| `troughDepthValue` | Trough depth | mm |
| `troughWidthValue` | Adjacent panel width | mm |

##### F. Anchorage Tab (`AnchorageTab`)
**Purpose**: Anchoring system inspection

**Anchor Count Group**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `numLowAnchors` | Number of low anchor points | - |
| `numHighAnchors` | Number of high anchor points | - |
| `numAnchorsPassFail` | Sufficient anchors | "Sufficient number of anchor points per side" |

**Anchor Quality Checks**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `anchorAccessoriesPassFail` | Correct accessories | "Produced correct amount of stakes at 380mmx16mm..." |
| `anchorDegreePassFail` | Anchor angle | "Anchors are at an angle to the ground of 30° to 45°" |
| `anchorTypePassFail` | Anchor type | "Metal and permanently closed" |
| `pullStrengthPassFail` | Pull strength test | "Meets the 1600 newton pull requirement test..." |

##### G. Totally Enclosed Tab (`EnclosedTab`)
**Purpose**: Enclosed equipment specific checks

| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `exitNumberValue` | Number of exits | - |
| `exitNumberPassFail` | Adequate exits | "More than one exit if user count > 15..." |
| `exitsignVisiblePassFail` | Exit visibility | "Exit sign is always visible and user never more than 5m..." |

##### H. Materials Tab (`MaterialsTab`)
**Purpose**: Material quality and compliance

**Material Safety Checks**:
| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `ropeSizePassFail` | Rope specifications | "Between 18mm - 45mm. Fixed at both ends..." |
| `clamberPassFail` | Clamber netting | "Not monofilament, no entrapment and at least 12mm diameter..." |
| `retentionNettingPassFail` | Retention netting | "Vertical netting > 1m mesh size is no greater than 30mm..." |
| `zipsPassFail` | Zip functionality | "Zips easily open/close and covered..." |
| `windowsPassFail` | Window safety | "Retention netting strong enough to support heaviest user..." |
| `artworkPassFail` | Artwork compliance | "Not flaking - Manufacturer to supply conformity report to EN 71-3" |
| `threadPassFail` | Thread strength | "Manufacturer to provide conformity report..." |
| `fabricPassFail` | Fabric strength | "Manufacturer to provide conformity report..." |
| `fireRetardentPassFail` | Fire retardancy | "Manufacturer to provide conformity report to confirm FR" |

**Rope Size Measurement**:
| Control | Purpose | Unit |
|---------|---------|------|
| `ropesizeValue` | Rope diameter | mm |

##### I. Fan Tab (`FanTab`)
**Purpose**: Blower/fan system inspection

| Control | Purpose | Default Comment |
|---------|---------|-----------------|
| `blowerSizeComment` | Blower size assessment | "Reaches 1.0 kpa pressure on a 1.5hp blower" |
| `blowerFlapPassFail` | Return flap check | "Blower return flap present and correct..." |
| `blowerFingerPassFail` | Finger probe test | "8mm finger probe does not pass and come into contact..." |
| `patPassFail` | PAT test | "Customer own certificate" |
| `blowerVisualPassFail` | Visual inspection | "Passes visual inspection and suitable" |
| `blowerSerial` | Blower serial number | - |

**Special Feature**:
- Link to PAT Log service: `linkLabel1` points to https://patlog.co.uk/

##### J. Notes - R/A Tab (`RiskAssessmentTab`)
**Purpose**: Risk assessment and additional notes

| Control | Purpose | Content |
|---------|---------|---------|
| `riskAssessmentNotes` | Comprehensive risk assessment | Pre-populated risk assessment template |

### 2. Useful Calculations Tab (`tabPage2`)
**Purpose**: Reference information for inspectors

**Content**:
- Anchor point calculation formula: `((Area² * 114)/1600) * 1.5`
- Slide calculation reference images
- Safety standard references

### 3. Records Tab (`tabPage12`)
**Purpose**: Database management and search functionality

**Search Controls**:
| Control | Purpose | Functionality |
|---------|---------|---------------|
| `loadAllRecordsBtn` | Load all records | Displays all historic inspections |
| `searchByOwnerBtn` | Search by owner | Finds inspections by unit owner |
| `uniqueReportNumberSearchBtn` | Search by report number | Finds specific inspection |
| `clrRecordsBtn` | Clear results | Clears displayed records |
| `loadReport` | Load inspection | Loads selected record into form |

**Data Display**:
| Control | Purpose |
|---------|---------|
| `records` | DataGridView for displaying search results |

## Action Buttons (Global)

| Button | Location | Purpose | Event Handler |
|--------|----------|---------|---------------|
| `saveBtn` | Bottom toolbar | Save inspection to database | Form1.cs:764 |
| `newBtn` | Bottom toolbar | Clear form for new inspection | Form1.cs:769 |
| `createPDFBtn` | Bottom toolbar | Generate PDF report | Form1.cs:774 |

## Control Validation and Behavior

### Numeric Control Precision
- **1 decimal place**: Unit dimensions (width, length, height)
- **2 decimal places**: All height measurements, distances, pressures
- **Whole numbers**: User counts, stitch length, rope sizes, evacuation time

### Cross-Tab Synchronization
1. **Permanent Roof Fields**: `permanentRoofChecked` ↔ `slidePermRoofedCheck`
   - Changes to either automatically update the other
   - Handles roof requirement compliance

### Default Values and Pre-Population
- **Inspection Location**: "On site"
- **Inspection Date**: Current date
- **Testimony**: Standard EN 14960:2019 compliance statement
- **Comment Fields**: Pre-populated with relevant safety criteria
- **Remaining Slide Wall Height**: Default 0.06m (60mm)

### File Upload Workflows
1. **Equipment Photo**: `uploadPhotoBtn` → File dialog → `unitPic` display
2. **Inspector Logo**: `selectLogoBtn` → File dialog → `inspectorsLogo` display

### Data Persistence Workflow
1. **Save**: All form data → SQLite database
2. **Load**: Database record → Populate all form fields
3. **New**: Clear all fields, reset to defaults
4. **PDF**: Generate formatted report from current form data

## UI Navigation Flow

### Primary Workflow:
1. **Start**: New inspection (clear form)
2. **Global Details**: Enter inspector and equipment basic info
3. **Unit Details**: Specifications and photo
4. **Measurements**: User Height/Count → Slide → Structure tabs
5. **Safety Checks**: Structure Cont. → Anchorage → Materials → Fan
6. **Special Cases**: Totally Enclosed (if applicable)
7. **Assessment**: Risk Assessment notes
8. **Finalize**: Pass/Fail decision, save, generate PDF

### Secondary Workflows:
- **Search/Load**: Records tab → Search → Load inspection
- **Reference**: Useful Calculations tab for formulas
- **Modify**: Load existing → Edit → Save

This UI workflow provides a comprehensive inspection process ensuring all safety standards are systematically evaluated and documented.