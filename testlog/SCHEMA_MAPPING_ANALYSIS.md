# Database Schema Mapping Analysis

## Overview
This document compares the original C# SQLite database structure from DATABASE_OPERATIONS.md with the current Rails schema to identify column mappings and potential hallucinated functionality.

## Original Database Structure
The original app had a single `Inspections` table with **142 fields** stored in SQLite.

## Current Rails Schema Structure
The Rails app uses **8 main tables** plus ActiveStorage tables, with normalized relationships.

---

## Table Structure Comparison

### Core Inspection Data

#### ✅ MAPPED: Primary Inspection Table
| **Original Column** | **New Table.Column** | **Type Change** | **Notes** |
|-------------------|---------------------|-----------------|-----------|
| `TagID` (INTEGER PK) | `inspections.id` (STRING) | INTEGER → STRING | Rails uses custom string IDs |
| `inspectionCompany` | `inspections.inspection_company_name` | TEXT → STRING | Direct mapping |
| `inspectionDate` | `inspections.inspection_date` | TEXT → DATETIME | Better type safety |
| `RPIIRegNum` | `inspections.rpii_registration_number` | TEXT → STRING | Field name normalized |
| `placeInspected` | `inspections.place_inspected` | TEXT → STRING | Direct mapping |
| `passed` | `inspections.passed` | INTEGER → BOOLEAN | Better type |
| `Testimony` | `inspections.comments` | TEXT → TEXT | Renamed for clarity |

#### ✅ MAPPED: Unit/Equipment Data
| **Original Column** | **New Table.Column** | **Type Change** | **Notes** |
|-------------------|---------------------|-----------------|-----------|
| `unitDescription` | `units.description` | TEXT → STRING | Normalized to separate table |
| `unitManufacturer` | `units.manufacturer` | TEXT → STRING | Normalized to separate table |
| `unitWidth` | `units.width` | REAL → DECIMAL(8,2) | Better precision |
| `unitLength` | `units.length` | REAL → DECIMAL(8,2) | Better precision |
| `unitHeight` | `units.height` | REAL → DECIMAL(8,2) | Better precision |
| `serial` | `units.serial_number` | TEXT → STRING | Field renamed |
| `unitType` | `units.unit_type` | TEXT → STRING | Direct mapping |
| `unitOwner` | `units.owner` | TEXT → STRING | Direct mapping |
| `image` | ActiveStorage attachment | TEXT → BLOB | Modern file handling |

---

## Assessment Category Mappings

### ✅ MAPPED: User Height Assessment (22 → 13 fields)
| **Original Column** | **New Column** | **Status** |
|-------------------|----------------|------------|
| `containingWallHeight` | `user_height_assessments.containing_wall_height` | ✅ Mapped |
| `containingWallHeightComment` | Missing comment field | ❌ Lost |
| `platformHeight` | `user_height_assessments.platform_height` | ✅ Mapped |
| `platformHeightComment` | Missing comment field | ❌ Lost |
| `slideBarrierHeight` | Missing | ❌ Lost (moved to slide_assessments?) |
| `slideBarrierHeightComment` | Missing | ❌ Lost |
| `remainingSlideWallHeight` | Missing | ❌ Lost |
| `remainingSlideWallHeightComment` | Missing | ❌ Lost |
| `permanentRoof` | `user_height_assessments.permanent_roof` | ✅ Mapped |
| `permanentRoofComment` | Missing comment field | ❌ Lost |
| `userHeight` | `user_height_assessments.user_height` | ✅ Mapped |
| `userHeightComment` | `user_height_assessments.user_height_comment` | ✅ Mapped |
| `playAreaLength` | `user_height_assessments.play_area_length` | ✅ Mapped |
| `playAreaLengthComment` | Missing comment field | ❌ Lost |
| `playAreaWidth` | `user_height_assessments.play_area_width` | ✅ Mapped |
| `playAreaWidthComment` | Missing comment field | ❌ Lost |
| `negAdjustment` | `user_height_assessments.negative_adjustment` | ✅ Mapped |
| `negAdjustmentComment` | Missing comment field | ❌ Lost |
| `usersat1000mm` | `user_height_assessments.users_at_1000mm` | ✅ Mapped |
| `usersat1200mm` | `user_height_assessments.users_at_1200mm` | ✅ Mapped |
| `usersat1500mm` | `user_height_assessments.users_at_1500mm` | ✅ Mapped |
| `usersat1800mm` | `user_height_assessments.users_at_1800mm` | ✅ Mapped |

### ✅ MAPPED: Slide Assessment (17 → 11 fields)
| **Original Column** | **New Column** | **Status** |
|-------------------|----------------|------------|
| `slidePlatformHeight` | `slide_assessments.slide_platform_height` | ✅ Mapped |
| `slidePlatformHeightComment` | `slide_assessments.slide_platform_height_comment` | ✅ Mapped |
| `slideWallHeight` | `slide_assessments.slide_wall_height` | ✅ Mapped |
| `slideWallHeightComment` | Missing comment field | ❌ Lost |
| `slideFirstMetreHeight` | `slide_assessments.slide_first_metre_height` | ✅ Mapped |
| `slideFirstMetreHeightComment` | Missing comment field | ❌ Lost |
| `slideBeyondFirstMetreHeight` | `slide_assessments.slide_beyond_first_metre_height` | ✅ Mapped |
| `slideBeyondFirstMetreHeightComment` | Missing comment field | ❌ Lost |
| `slidePermanentRoof` | `slide_assessments.slide_permanent_roof` | ✅ Mapped |
| `slidePermanentRoofComment` | Missing comment field | ❌ Lost |
| `clamberNettingPass` | `slide_assessments.clamber_netting_pass` | ✅ Mapped |
| `clamberNettingComment` | Missing comment field | ❌ Lost |
| `runoutValue` | `slide_assessments.runout_value` | ✅ Mapped |
| `runoutPass` | `slide_assessments.runout_pass` | ✅ Mapped |
| `runoutComment` | Missing comment field | ❌ Lost |
| `slipSheetPass` | `slide_assessments.slip_sheet_pass` | ✅ Mapped |
| `slipSheetComment` | Missing comment field | ❌ Lost |

### ✅ MAPPED: Structure Assessment (34 → 24 fields)
Many structure assessment fields map correctly, but several comment fields are missing.

### ✅ MAPPED: Anchorage Assessment (12 → 8 fields)
| **Original Column** | **New Column** | **Status** |
|-------------------|----------------|------------|
| `numLowAnchors` | `anchorage_assessments.num_low_anchors` | ✅ Mapped |
| `numHighAnchors` | `anchorage_assessments.num_high_anchors` | ✅ Mapped |
| `numAnchorsPass` | `anchorage_assessments.num_anchors_pass` | ✅ Mapped |
| `numAnchorsComment` | Missing comment field | ❌ Lost |
| `anchorAccessoriesPass` | `anchorage_assessments.anchor_accessories_pass` | ✅ Mapped |
| `anchorAccessoriesComment` | Missing comment field | ❌ Lost |
| `anchorDegreePass` | `anchorage_assessments.anchor_degree_pass` | ✅ Mapped |
| `anchorDegreeComment` | Missing comment field | ❌ Lost |
| `anchorTypePass` | `anchorage_assessments.anchor_type_pass` | ✅ Mapped |
| `anchorTypeComment` | Missing comment field | ❌ Lost |
| `pullStrengthPass` | `anchorage_assessments.pull_strength_pass` | ✅ Mapped |
| `pullStrengthComment` | Missing comment field | ❌ Lost |

### ✅ MAPPED: Materials Assessment (20 → 10 fields)
Most pass/fail fields map, but comment fields are missing.

### ❌ PARTIALLY MAPPED: Fan/Blower Assessment
| **Original Column** | **New Column** | **Status** |
|-------------------|----------------|------------|
| `fanSizeComment` | Missing | ❌ Lost |
| `blowerFlapPass` | Missing | ❌ Lost |
| `blowerFlapComment` | Missing | ❌ Lost |
| `blowerFingerPass` | Missing | ❌ Lost |
| `blowerFingerComment` | Missing | ❌ Lost |
| `patPass` | Missing | ❌ Lost |
| `patComment` | Missing | ❌ Lost |
| `blowerVisualPass` | Missing | ❌ Lost |
| `blowerVisualComment` | Missing | ❌ Lost |
| `blowerSerial` | Missing | ❌ Lost |

### ❌ MISSING: Totally Enclosed Equipment
| **Original Column** | **Status** |
|-------------------|------------|
| `exitNumber` | ❌ No equivalent table |
| `exitNumberPass` | ❌ No equivalent table |
| `exitNumberComment` | ❌ No equivalent table |
| `exitVisiblePass` | ❌ No equivalent table |
| `exitVisibleComment` | ❌ No equivalent table |

---

## 🚨 HALLUCINATED FEATURES

### New Tables NOT in Original Database

#### 🔍 SUSPECT: `enclosed_assessments` (29 fields)
**COMPLETELY NEW** - This entire table appears to be hallucinated:
- `enclosure_type`, `ceiling_height`, `floor_area_sqm`
- `occupancy_limit`, `ventilation_type`, `air_changes_per_hour`
- `emergency_exits`, `exit_width_cm`, `exit_visibility`
- `emergency_lighting`, `fire_extinguisher`, `first_aid_kit`
- `supervision_visibility`, `internal_obstacles`
- `ceiling_attachments`, `wall_attachments`
- `structural_integrity`, `material_flame_rating`
- `seam_construction`, `transparency_panels`
- `interior_temperature`, `humidity_level`, `air_quality`
- `noise_level_interior`, `cleaning_schedule`
- `sanitization_protocol`, `maintenance_access`, `equipment_storage`

**VERDICT**: ❌ **LIKELY HALLUCINATED** - Original only had 6 "Totally Enclosed Equipment" fields

#### 🔍 SUSPECT: `fan_assessments` (25 fields) 
**SIGNIFICANTLY EXPANDED** from original 10 fields:
- Original: Basic pass/fail checks + serial
- New: Detailed electrical ratings, power specs, safety features
- Added: `blower_power_rating`, `blower_voltage`, `electrical_cord_length`
- Added: `gfi_protection`, `weatherproof_rating`, `air_flow_cfm`
- Added: `operating_pressure`, `noise_level_db`, `ul_listing`

**VERDICT**: ⚠️ **MOSTLY HALLUCINATED** - Original was much simpler

#### 🔍 SUSPECT: `inspector_companies` table
**COMPLETELY NEW** - No equivalent in original:
- Company management system
- RPII verification workflow
- Multi-user company relationships

**VERDICT**: ❌ **HALLUCINATED** - Original was single-user

### New Inspection Fields NOT in Original

#### 🔍 SUSPECT: Advanced Inspection Tracking
```sql
-- These fields don't exist in original 142-field schema:
status                   -- "draft" workflow system
finalized_at            -- Workflow timestamps  
finalized_by_id         -- Multi-user finalization
general_notes           -- Separate from main comments
recommendations         -- Separate recommendations field
weather_conditions      -- Environmental tracking
ambient_temperature     -- Environmental measurements
inspector_signature     -- Digital signatures
signature_timestamp     -- Signature workflow
```

**VERDICT**: ⚠️ **LIKELY HALLUCINATED** - Original was simpler

---

## Summary Statistics

### ✅ Successfully Mapped: ~70 fields
- Core inspection data: **7/7 fields**
- Unit data: **8/9 fields** 
- User height: **13/22 fields** (comment fields lost)
- Slide assessment: **11/17 fields** (comment fields lost)
- Structure: **24/34 fields** (comment fields lost)
- Anchorage: **8/12 fields** (comment fields lost)
- Materials: **10/20 fields** (comment fields lost)

### ❌ Missing from New Schema: ~35 fields
- Mostly comment fields that provided detailed notes
- Some specific measurement fields
- Totally Enclosed Equipment (6 fields completely missing)

### 🚨 Likely Hallucinated: ~70+ fields
- **Enclosed assessments table**: 29 fields (COMPLETELY NEW)
- **Fan assessments expansion**: 15+ fields beyond original
- **Inspector companies**: Entire workflow system
- **Advanced inspection workflow**: Status, signatures, finalization

---

## Recommendations

1. **Review enclosed_assessments table** - Appears to be AI hallucination
2. **Simplify fan_assessments** - Return to original 10 basic fields  
3. **Consider inspector_companies necessity** - May be over-engineering
4. **Add missing comment fields** - Important for inspection notes
5. **Verify business requirements** - Confirm which new features are actually needed

The Rails app has been significantly over-engineered compared to the original simple inspection tool.