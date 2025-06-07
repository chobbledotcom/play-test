# RPII Utility - Business Rules and Safety Standards

## Overview

This document outlines the business rules, safety standards, validation logic, and inspection criteria implemented in the RPII (Recreational Product Inspection Institute) Utility application. These rules ensure compliance with safety standards for inflatable recreational equipment.

## User Height Categories and Capacity Standards

### Height-Based User Classifications

The system tracks user capacity across four distinct height categories:

| Height Category   | User Age Group | Field Name      | Purpose                               |
| ----------------- | -------------- | --------------- | ------------------------------------- |
| **1.0m (1000mm)** | Young children | `usersat1000mm` | Maximum users under 1 meter height    |
| **1.2m (1200mm)** | Children       | `usersat1200mm` | Maximum users under 1.2 meters height |
| **1.5m (1500mm)** | Adolescents    | `usersat1500mm` | Maximum users under 1.5 meters height |
| **1.8m (1800mm)** | Adults         | `usersat1800mm` | Maximum users under 1.8 meters height |

### Capacity Calculation Rules

- User capacity must be determined based on the tallest user height (`userHeight` field)
- Negative adjustments (`negAdjustment`) can reduce available play area
- Play area dimensions (`playAreaLength`, `playAreaWidth`) determine base capacity

## Slide Safety Standards

### Containing Wall Height Requirements

Based on the slide calculation references (slide-calc-1.png and slide-calc-2.png):

#### Height Categories for Slides (in millimeters):

1. **< 600mm**: No containing walls required
2. **600mm - 3000mm**: Containing walls required of user height
3. **> 3000mm**: Containing walls required 1.25 times user height
4. **> 3000mm (Alternative)**: Add a permanent roof
5. **> 6000mm**: Both containing walls AND permanent roof required

### Slide Platform and Wall Heights

| Measurement           | Field                         | Validation Rule                        | Safety Standard     |
| --------------------- | ----------------------------- | -------------------------------------- | ------------------- |
| Slide Platform Height | `slidePlatformHeight`         | Must match platform measurements       | Consistency check   |
| Slide Wall Height     | `slideWallHeight`             | Must meet containing wall requirements | Height-based safety |
| First Metre Height    | `slideFirstMetreHeight`       | Must be measured from slide start      | Slope safety        |
| Beyond First Metre    | `slideBeyondFirstMetreHeight` | 50% of tallest user height minimum     | Run-out safety      |

### Run-out Requirements

From slide-calc-2.png specifications:

- **Minimum Run-out Length**: 50% of highest platform height
- **Absolute Minimum**: 300mm in any case
- **Maximum Inclination**: Not more than 10°
- **Stop-wall Addition**: If fitted, adds 50cm to required run-out length
- **Containing Wall Height**: Must be at least 50% of user height on run-out sides

## Measurement Precision Standards

### Decimal Place Requirements

| Category                  | Precision        | Fields                                  |
| ------------------------- | ---------------- | --------------------------------------- |
| **Unit Dimensions**       | 1 decimal place  | `unitWidth`, `unitLength`, `unitHeight` |
| **Height Measurements**   | 2 decimal places | All height-related measurements         |
| **Distance Measurements** | 2 decimal places | `runoutValue`, `blowerTubeLength`       |
| **Pressure Values**       | 2 decimal places | `unitPressureValue`                     |
| **User Counts**           | Whole numbers    | All `usersat*` fields                   |

## Pass/Fail Validation Logic

### Binary Pass/Fail Fields

All pass/fail determinations are stored as boolean values (INTEGER 0/1 in database):

- **0 = Fail/False**
- **1 = Pass/True**

### Critical Safety Checks

#### Structural Integrity (Required Pass)

- `seamIntegrityPass`: Seam integrity inspection
- `lockStitchPass`: Lock stitching quality
- `airLossPass`: Air retention test
- `straightWallsPass`: Wall verticality check
- `sharpEdgesPass`: Sharp edge safety check

#### Slide-Specific Safety (Required Pass)

- `clamberNettingPass`: Steps/climbing netting safety
- `runoutPass`: Run-out length and angle compliance
- `slipSheetPass`: Slip sheet integrity

#### Anchoring System (Required Pass)

- `numAnchorsPass`: Adequate number of anchors
- `anchorTypePass`: Appropriate anchor type
- `pullStrengthPass`: Anchor pull strength test
- `anchorDegreePass`: Anchor angle compliance

#### Materials Safety (Required Pass)

- `fabricPass`: Fabric strength test
- `fireRetardentPass`: Fire retardancy compliance
- `threadPass`: Thread strength and quality

#### Electrical Safety (Required Pass)

- `patPass`: Portable Appliance Test (PAT)
- `blowerVisualPass`: Visual blower inspection
- `blowerFingerPass`: Finger probe test

### Final Inspection Determination

**Location**: Form1.cs:428, Form1.cs:1338-1342

The final inspection result (`passed` field) is determined by:

- Manual inspector assessment via radio button selection
- All critical safety checks must pass
- PDF report shows "Passed Inspection" (green) or "Failed Inspection" (red)

## Measurement Validation Rules

### Range Validation

While specific ranges aren't hardcoded, the application enforces:

#### Positive Values Required

- All dimension measurements must be positive
- User counts must be non-negative integers
- Pressure values must be positive

#### Logical Consistency Checks

- Unit dimensions must be realistic for inflatable equipment
- User heights must be within reasonable human ranges
- Platform heights must be achievable for inflatable structures

### Cross-Field Validation

#### Permanent Roof Synchronization

**Location**: Form1.cs:837-847

- `permanentRoofChecked` and `slidePermRoofedCheck` are synchronized
- Changes to either field automatically update the other
- Ensures consistency between User Height and Slide tabs

#### Height Relationship Validation

- `userHeight` must be ≤ tallest user category in use
- Slide heights must be logically related to platform heights
- Containing wall heights must meet minimum requirements for user heights

## Equipment Category Rules

### Unit Type Classification

The system handles different equipment types with category-specific rules:

#### Totally Enclosed Equipment

- **Required**: Minimum number of exits (`exitNumber`)
- **Required**: Exit visibility (`exitVisiblePass`)
- **Safety Standard**: Adequate evacuation capability

#### Slide Equipment

- **Required**: All slide-specific measurements
- **Required**: Run-out compliance
- **Safety Standard**: Height-based containing wall requirements

#### Standard Bounce Equipment

- **Required**: Basic structural checks
- **Required**: User capacity validation
- **Safety Standard**: Appropriate anchoring

## Evacuation Time Standards

### Time-Based Safety Requirements

| Measurement          | Field          | Standard            | Critical Level         |
| -------------------- | -------------- | ------------------- | ---------------------- |
| Evacuation Time      | `evacTime`     | Must be tested      | Inspector discretion   |
| Evacuation Pass/Fail | `evacTimePass` | Required assessment | Must pass for approval |

## Pressure and Stability Requirements

### Operating Pressure Standards

- **Measurement**: `unitPressureValue` (in appropriate units)
- **Assessment**: `unitPressurePass` (must pass)
- **Validation**: Must maintain adequate pressure for safety

### Stability Requirements

- **Assessment**: `unitStablePass` (must pass)
- **Critical**: Unit must remain stable under normal use conditions
- **Testing**: Inspector must verify stability during inspection

## Blower Tube Distance Standards

### Safety Distance Requirements

- **Measurement**: `blowerTubeLength` (in meters, 2 decimal places)
- **Assessment**: `blowerTubeLengthPass` (must pass)
- **Purpose**: Ensure adequate distance for safety and proper airflow

## Step and Ramp Safety Standards

### Size and Safety Requirements

- **Measurement**: `stepSizeValue` (in appropriate units)
- **Assessment**: `stepSizePass` (must pass)
- **Fall-off Height**: `falloffHeightValue` with pass/fail assessment
- **Critical**: Steps must be appropriate size for safe use

## Trough Dimensions (for slides)

### Dimensional Requirements

- **Depth**: `troughDepthValue` (measured value)
- **Width**: `troughWidthValue` (measured value)
- **Assessment**: `troughPass` (combined pass/fail for both dimensions)
- **Purpose**: Ensure safe slide channel dimensions

## Data Integrity Rules

### Required Fields for Complete Inspection

1. **Inspector Information**: Company name, date, RPII registration
2. **Equipment Identification**: Description, manufacturer, serial number
3. **Safety Measurements**: All applicable height and dimension measurements
4. **Pass/Fail Assessments**: All relevant safety checks for equipment type
5. **Final Determination**: Overall pass/fail decision with testimony

### Audit Trail Requirements

- **Inspection Date**: Must be recorded (`inspectionDate`)
- **Inspector Credentials**: RPII registration number required
- **Equipment Owner**: Must be documented (`unitOwner`)
- **Location**: Inspection location must be recorded (`placeInspected`)

## Risk Assessment Standards

### Comprehensive Assessment Requirement

- **Field**: `riskAssessment` (free-form text)
- **Requirement**: Must document any identified risks
- **Purpose**: Provide comprehensive safety evaluation beyond checklist items

### Testimony Requirements

- **Field**: `Testimony` (rich text)
- **Purpose**: Inspector's detailed findings and recommendations
- **Usage**: Printed on final inspection report

## Validation Error Handling

### Data Entry Validation

- **Type Safety**: Numeric fields enforce proper data types
- **Range Checking**: UI controls prevent unrealistic values
- **Required Fields**: Critical fields must be completed before saving
- **Format Validation**: Dates, numbers, and text must be properly formatted

### Business Logic Validation

- **Consistency Checks**: Related measurements must be logically consistent
- **Safety Compliance**: All safety-critical checks must pass for overall approval
- **Equipment Type**: Validation rules apply based on equipment category

This business rules documentation ensures consistent application of safety standards and provides clear guidance for proper equipment inspection and certification.
