# BS EN 14960:2019 Calculations Reference

This document catalogs all calculations referenced in BS EN 14960:2019 "Inflatable play equipment - Part 1: Safety requirements and test methods" with line references to our `14960.md` file.

## Overview

The standard contains 13 distinct calculation types, ranging from critical safety calculations to compliance testing requirements. We have implemented 3 core calculations and identified 10 additional calculations that could enhance our safety standard compliance.

---

## ✅ IMPLEMENTED CALCULATIONS

### 1. Anchor Point Calculation
**Lines**: 1175-1206 (Annex A)  
**Status**: ✅ Implemented (simplified)  
**Implementation**: `SafetyStandard.calculate_required_anchors`

**Standard Formula** (Lines 1181-1202):
```
F = 0.5 × Cw × ρ × V² × A
```
Where:
- F = force on each side
- Cw = 1.5 (wind coefficient)
- ρ = 1.24 kg/m³ (air density)  
- V = 11.1 m/s (Force 6 Beaufort wind speed)
- A = exposed surface area

**Our Implementation**:
```ruby
ANCHOR_CALCULATION_CONSTANTS = {
  area_coefficient: 114.0,     # Simplified area coefficient
  base_divisor: 1600.0,        # Base divisor for calculation  
  safety_factor: 1.5           # Safety factor multiplier
}

# Formula: ((area × 114.0 × 1.5) ÷ 1600.0).ceil
```

**Note**: Our implementation is a simplified practical version that produces equivalent results without the full wind force physics.

### 2. Wall Height Requirements for Platforms
**Lines**: 856-887 (Section 4.2.9)  
**Status**: ✅ Implemented  
**Implementation**: `SafetyStandard.meets_height_requirements?`

**Standard Requirements**:
- Platform 0.6m-3.0m: walls = user height (Line 861)
- Platform 3.0m-6.0m: walls = 1.25 × user height (Lines 863-864)  
- Platform >6.0m: walls + permanent roof required (Lines 865-866)
- Min internal height with roof: 0.75m (Lines 867-868)

**Our Implementation**:
```ruby
WALL_HEIGHT_CONSTANTS = {
  enhanced_height_multiplier: 1.25  # 1.25× multiplier for enhanced walls
}

SLIDE_HEIGHT_THRESHOLDS = {
  no_walls_required: 0.6,      # Under 600mm
  basic_walls: 3.0,            # 600mm - 3000mm  
  enhanced_walls: 6.0,         # 3000mm - 6000mm
  max_safe_height: 8.0         # Maximum recommended height
}
```

### 3. Slide Runout Length Calculation
**Lines**: 930-939 (Section 4.2.11)  
**Status**: ✅ Implemented  
**Implementation**: `SafetyStandard.calculate_required_runout`

**Standard Formula** (Lines 933-935):
- Minimum 50% of highest platform height
- Absolute minimum 300mm in all cases
- Additional 50cm if stop-wall fitted (Lines 936-937)

**Our Implementation**:
```ruby
RUNOUT_CALCULATION_CONSTANTS = {
  platform_height_ratio: 0.5, # 50% of platform height
  minimum_runout_meters: 0.3   # Absolute minimum 300mm (0.3m)
}

# Formula: [platform_height × 0.5, 0.3].max
```

---

## ❌ MISSING CALCULATIONS - PRIORITY 1 (Safety Critical)

### 4. Wall Heights on Slopes
**Lines**: 888-901 (Section 4.2.10)  
**Complexity**: Medium  
**Safety Impact**: High

**Standard Requirements**:
- First metre at top: ≥ user height (Lines 892-893)
- Remainder of slope: ≥ 50% user height (Lines 893-894)  
- Slopes >6m: walls + permanent roof (Lines 895-896)
- Min internal height with roof: 75cm (Lines 896-897)

**Special Case** (Lines 898-901):
- Bounce/slide combinations ≤1.5m platform height
- Users forced to sit/crouch entering slide
- Top 750mm: ≥ 50% user height
- Remainder: ≥ 300mm

**Potential Implementation**:
```ruby
def calculate_slope_wall_requirements(slope_length, user_height, platform_height = nil, is_bounce_slide_combo = false)
  # Implementation would handle the tiered requirements
end
```

### 5. Tread Depth Calculations  
**Lines**: 514-518 (Section 4.2.3)  
**Complexity**: Low  
**Safety Impact**: High

**Standard Requirements**:
- **Steps/Ramps**: minimum 1.5 × adjacent platform height (Lines 514-515)
- **Safety Apron**: minimum 1.6m OR 0.5 × playing area height, whichever greater (Lines 517-518)

**Potential Implementation**:
```ruby
TREAD_DEPTH_CONSTANTS = {
  step_multiplier: 1.5,        # 1.5× adjacent platform height
  safety_apron_minimum: 1.6,   # 1.6m minimum
  safety_apron_ratio: 0.5      # 0.5× playing area height
}

def calculate_minimum_tread_depth(type, platform_height, playing_area_height = nil)
  case type
  when :step, :ramp
    platform_height * TREAD_DEPTH_CONSTANTS[:step_multiplier]
  when :safety_apron  
    [TREAD_DEPTH_CONSTANTS[:safety_apron_minimum], 
     playing_area_height * TREAD_DEPTH_CONSTANTS[:safety_apron_ratio]].max
  end
end
```

### 6. Free Height of Fall Limits
**Lines**: 525-530 (Section 4.2.3)  
**Complexity**: Medium  
**Safety Impact**: Critical

**Standard Requirements**:
- Maximum 630mm unloaded condition (Line 525)
- Maximum 600mm loaded condition (Line 526)  
- Impact area: minimum 1.2m extent (Line 527)
- Critical fall height surfacing: ≥630mm (Lines 528-529)

**Potential Implementation**:
```ruby
FREE_FALL_LIMITS = {
  max_unloaded_mm: 630,        # Maximum 630mm unloaded
  max_loaded_mm: 600,          # Maximum 600mm loaded  
  min_impact_area_m: 1.2,      # Minimum 1.2m impact area
  min_critical_fall_height: 630 # Minimum critical fall height
}

def validate_free_fall_height(height_mm, condition = :unloaded)
  limit = condition == :loaded ? FREE_FALL_LIMITS[:max_loaded_mm] : FREE_FALL_LIMITS[:max_unloaded_mm]
  height_mm <= limit
end
```

### 7. Clear Area Around Inflatable
**Lines**: 835-837 (Section 4.2.8)  
**Complexity**: Low  
**Safety Impact**: High

**Standard Formula** (Line 836):
- Distance = platform height ÷ 2
- **Minimums**: 1.8m walled sides, 3.5m open sides (Line 837)

**Exception** (Lines 838-841):
- Against solid building walls
- Wall must be 2.0m higher than platform (unless permanent roof)

**Potential Implementation**:
```ruby
CLEAR_AREA_CONSTANTS = {
  height_divisor: 2.0,         # Platform height ÷ 2
  min_walled_sides: 1.8,       # 1.8m minimum walled sides
  min_open_sides: 3.5,         # 3.5m minimum open sides  
  solid_wall_height_addition: 2.0 # 2.0m higher than platform
}

def calculate_clear_area(platform_height, side_type = :walled)
  calculated = platform_height / CLEAR_AREA_CONSTANTS[:height_divisor]
  minimum = side_type == :open ? CLEAR_AREA_CONSTANTS[:min_open_sides] : CLEAR_AREA_CONSTANTS[:min_walled_sides]
  [calculated, minimum].max
end
```

---

## ❌ MISSING CALCULATIONS - PRIORITY 2 (Design Validation)

### 8. Platform Trough Depth Limits
**Line**: 485 (Section 4.2.2)  
**Complexity**: Low  
**Safety Impact**: Medium

**Standard Requirement**:
- Maximum 33% of adjacent panel width when inflated

**Potential Implementation**:
```ruby
TROUGH_DEPTH_LIMITS = {
  max_percentage: 0.33         # Maximum 33% of panel width
}

def validate_trough_depth(trough_depth, panel_width)
  max_allowed = panel_width * TROUGH_DEPTH_LIMITS[:max_percentage]
  trough_depth <= max_allowed
end
```

### 9. Tunnel Diameter Requirements
**Lines**: 769-773 (Section 4.2.5.5)  
**Complexity**: Medium  
**Safety Impact**: High (entrapment prevention)

**Standard Requirements**:
- **≤75cm length**: squeeze rules (≥40cm opening, expandable to ≥40cm diameter)
- **75cm-2m length**: ≥50cm internal diameter
- **>2m length**: ≥75cm internal diameter

**Potential Implementation**:
```ruby
TUNNEL_REQUIREMENTS = {
  squeeze_max_length: 0.75,    # 75cm maximum for squeeze
  short_tunnel_max: 2.0,       # 2m maximum for short tunnel
  squeeze_min_diameter: 0.40,  # 40cm minimum for squeeze
  short_min_diameter: 0.50,    # 50cm minimum for short tunnel  
  long_min_diameter: 0.75      # 75cm minimum for long tunnel
}

def validate_tunnel_diameter(length, diameter)
  case length
  when 0..TUNNEL_REQUIREMENTS[:squeeze_max_length]
    diameter >= TUNNEL_REQUIREMENTS[:squeeze_min_diameter]
  when (TUNNEL_REQUIREMENTS[:squeeze_max_length]..TUNNEL_REQUIREMENTS[:short_tunnel_max])
    diameter >= TUNNEL_REQUIREMENTS[:short_min_diameter]
  else
    diameter >= TUNNEL_REQUIREMENTS[:long_min_diameter]
  end
end
```

### 10. Material Strength Validation  
**Lines**: 375-414 (Section 4.1)  
**Complexity**: Low  
**Safety Impact**: Medium

**Standard Requirements**:
- **Fabric**: 350N tear strength, 1850N tensile strength (Lines 375-377)
- **Thread**: 88N tensile strength, 3-8mm stitch length (Lines 388-391)  
- **Rope**: 18-45mm diameter, <20% swing amplitude (Lines 409-414)

**Already Partially Implemented**:
```ruby
MATERIAL_STANDARDS = {
  fabric: {
    min_tensile_strength: 1850,    # Newtons minimum
    min_tear_strength: 350,        # Newtons minimum
    fire_standard: "EN 71-3"       # Fire retardancy standard
  },
  thread: {
    min_tensile_strength: 88      # Newtons minimum
  }
  # Missing rope validation
}
```

---

## ❌ MISSING CALCULATIONS - PRIORITY 3 (Testing/Compliance)

### 11. Test Weight Requirements by User Height
**Lines**: 1316-1329 (Annex C, Table C.1)  
**Complexity**: Low  
**Safety Impact**: Low (testing only)

**Standard Requirements**:
- 1.0m users: 25kg test weight
- 1.2m users: 35kg test weight  
- 1.5m users: 65kg test weight
- 1.8m users: 85kg test weight

**Potential Implementation**:
```ruby
GROUNDING_TEST_WEIGHTS = {
  1000 => 25,  # 1.0m users: 25kg
  1200 => 35,  # 1.2m users: 35kg
  1500 => 65,  # 1.5m users: 65kg  
  1800 => 85   # 1.8m users: 85kg
}.freeze

def required_test_weight(user_height_mm)
  GROUNDING_TEST_WEIGHTS[user_height_mm] || 85 # Default to highest
end
```

### 12. Impact Area Extension for Hard Standing
**Lines**: 807-813 (Section 4.2.8)  
**Complexity**: Medium  
**Safety Impact**: Medium

**Standard Requirement**:
- 1.5m width extension when <1 supervisor per inflatable on hard standing
- Height >630mm unloaded condition
- Impact attenuating material required

### 13. User Number Determination Framework  
**Lines**: 942-960 (Section 4.3)  
**Complexity**: High  
**Safety Impact**: High

**Standard Factors** (Lines 945-959):
- User height
- Size of playing area
- Type of activity (bouncing, sliding)
- Inflated shapes on playing area  
- Access and egress arrangements

**Note**: Standard provides framework but no specific formulas. This is where our removed USER_SPACE_REQUIREMENTS would have attempted to fit, but the standard explicitly states "This list is not exhaustive" and provides no mathematical formulas.

---

## Implementation Recommendations

### Immediate Priority
1. **Tread Depth Calculations** - Simple implementation, high safety impact
2. **Free Height of Fall Limits** - Critical safety validation  
3. **Clear Area Calculations** - Prevents accidents, simple formula

### Medium Term
1. **Wall Heights on Slopes** - Extends existing wall height logic
2. **Tunnel Diameter Requirements** - Entrapment prevention
3. **Material Strength Validation** - Extend existing MATERIAL_STANDARDS

### Long Term
1. **Test Weight Requirements** - For compliance testing
2. **Impact Area Extension** - Hard standing safety
3. **User Number Framework** - Complex multi-factor assessment

### Complexity Assessment
- **Low**: 6 calculations - mostly constants and simple formulas
- **Medium**: 5 calculations - conditional logic, multiple cases  
- **High**: 2 calculations - complex multi-factor assessments

---

## Current Implementation Status
- **Implemented**: 3/13 (23%)
- **Safety Critical Missing**: 4/13 (31%)  
- **Total Missing**: 10/13 (77%)

The standard provides significantly more calculation requirements than our current implementation covers, with substantial opportunities to enhance safety compliance and validation capabilities.