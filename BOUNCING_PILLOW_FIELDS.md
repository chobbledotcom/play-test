# Bouncing Pillow Assessment Fields

This document maps each field from the bouncing pillow inspection form to either existing assessments that can be reused or new assessments that need to be created.

## Assessment Strategy

### Existing Assessments to Reuse

1. **fan_assessments** - Covers entire Blower section

### New Assessments to Create

1. **bouncing_pillow_inflatable_assessments** - Inflatable-specific checks
2. **bouncing_pillow_site_assessments** - Site condition checks
3. **bouncing_pillow_impact_assessments** - Impact area and safety checks
4. **bouncing_pillow_fencing_assessments** - Fencing and containment checks

---

## 1. Inflatable Section → bouncing_pillow_inflatable_assessments

### Fields to include:

- **security_of_seams_pass** (boolean)
- **security_of_seams_comment** (text)
- **air_loss_points_pass** (boolean)
- **air_loss_points_comment** (text) - "No air loss points found when smoke test carried out"
- **foundation_pass** (boolean)
- **foundation_comment** (text) - "Sand", "Depth of sand was 11cm at lowest point"
- **gradient_average** (decimal) - "12.6 degrees"
- **gradient_average_pass** (boolean)
- **gradient_average_comment** (text) - "10 +13+15 = 38 38/3= 12.6"
- **fabric_fr_pass** (boolean)
- **fabric_fr_comment** (text)
- **fabric_strength_pass** (boolean)
- **fabric_strength_comment** (text)
- **internal_pressure** (decimal) - "0.43KPA"
- **internal_pressure_pass** (boolean)
- **internal_pressure_comment** (text)
- **grounding_pass** (boolean)
- **grounding_comment** (text)
- **deflation_evacuation_time** (integer) - "18 Minuets" [sic]
- **deflation_evacuation_time_pass** (boolean)
- **deflation_evacuation_time_comment** (text)
- **artwork_pass** (boolean)
- **artwork_comment** (text) - "Label"
- **identification_pass** (boolean)
- **identification_comment** (text) - "Marker", "Noted down by manufacture name"

---

## 2. Site Section → bouncing_pillow_site_assessments

### Fields to include:

- **slope** (decimal) - "L 5 degree"
- **slope_pass** (boolean)
- **slope_comment** (text) - "Less than 5degree of slope"
- **clear_area** (decimal) - "2.1m"
- **clear_area_pass** (boolean)
- **clear_area_comment** (text)
- **headroom_pass** (boolean)
- **headroom_comment** (text) - "Infinite", "Open top inflatable with no restrictions"

---

## 3. Impact Area Section → bouncing_pillow_impact_assessments

### Fields to include:

- **hard_objects_pass** (boolean)
- **hard_objects_comment** (text) - "None"
- **depth_of_impact_attenuation** (decimal) - "11cm"
- **depth_of_impact_attenuation_pass** (boolean)
- **depth_of_impact_attenuation_comment** (text) - "Measured in 14 locations around perimeter"
- **signage_pass** (boolean)
- **signage_comment** (text) - "Entrance"
- **number_of_users** (integer) - "22 Users"
- **number_of_users_pass** (boolean)
- **number_of_users_comment** (text)

---

## 4. Fencing Section → bouncing_pillow_fencing_assessments

### Fields to include:

- **distance** (decimal) - "2.3m"
- **distance_pass** (boolean)
- **distance_comment** (text)
- **height** (decimal) - "0.9m"
- **height_pass** (boolean)
- **height_comment** (text)
- **strength_pass** (boolean)
- **strength_comment** (text)
- **visibility_pass** (boolean)
- **visibility_comment** (text)
- **entrapment_pass** (boolean)
- **entrapment_comment** (text)
- **gateways** (integer) - "x2"
- **gateways_pass** (boolean)
- **gateways_comment** (text) - "There are 2 gateways however they are 90cm not 1m - low risk"

---

## 5. Blower Section → fan_assessments (REUSE EXISTING)

This section maps perfectly to the existing `fan_assessments` table:

- **Size & Type** → fan_size_type + fan_size_type_pass + fan_size_type_comment ("0.55kw 240v")
- **Identification** → blower_serial ("PON02", "Identification found on flap of blower")
- **Inlet/outlet mesh** → blower_finger_pass + blower_finger_comment ("Secure")
- **Wiring/cable/plug** → blower_visual_pass + blower_visual_comment
- **PAT test** → pat_pass + pat_comment + pat_date ("09/07/2025")
- **Casing** → blower_visual_pass + blower_visual_comment

---

## Summary

For bouncing pillow inspections, we will:

1. **Reuse** the existing `fan_assessments` table for all blower-related checks
2. **Create** four new assessment tables:
   - `bouncing_pillow_inflatable_assessments` (main inflatable checks + container)
   - `bouncing_pillow_site_assessments` (site conditions)
   - `bouncing_pillow_impact_assessments` (impact area safety)
   - `bouncing_pillow_fencing_assessments` (fencing and barriers)

This approach maintains consistency with the existing assessment structure where each assessment type has its own dedicated table with pass/fail/comment fields for each check.
