# Field Renames

**Time: 20m**

- Inspection:
  - Unit Name => Bounce Safe Number

For "Bounce Safe Number" I need to add per-site translations rather than per-language, because only one Play-Test site will be a #BounceSafe one, but I don't think that'll be too complicated.

# Add Notes

**Time: 10m**

- Structure:
  - Under main wall height: "This is not slides - that's the next page"
- Blowers:
  - "You must test and log for every blower for this unit"

# Field Additions

**Time: 10m**

# Field Changes

**Time: 30m**

- Structure:
  - Move blower tube length bit to blower section
  - Platform height: change to mm
  - Fall off height: change to mm

# Calculators

**Time: 20m**

- All:
  - Remove "Pass/Fail" from the calculation bits
  - Instead say something like "Under/above the calculated anchor points" in the breakdown
- Anchorage:
  - Make it clear that the calculation uses the box model
  - "Required anchors" => "Calculated **total** anchors required"
- Wall Heights:
  - If there's a permanent roof, we can skip the "Walls must be at least" message, make this clearer in the breakdown

# Layout

**Time: 30m** (more complicated than it seems - atm every field is required)

- Ropes - not required when N/A is selected

# PDF

**Time: 30m**

- Add a Disclaimer footer and fit signature in
- Move the photo up

# Design

**Time: 0m**

- Bigger logos

# Calculators / Source Code

- Platform height (non slide) calculation - get Spencer's input

## Bug Fixes (free)

- User Capacity => arrange the "Max users at X" fields horizontally
- PDF - Operator is listed twice

---

# Done

## Field Renames

- Blower:
  - Rename "Blower size" and "Blower serial number" to "size(s)" and "number(s)"
- Inspection:
  - Serial Number => Manufacturer Serial Number
- Structure/User Height:
  - Containing Platform Wall Height => Main Wall Height
  - "Stitch Length" => "Stitching"
  - "Sharp Angles or Oblique Edges" => "Sharp Angles or Edges"
- Anchorage:
  - Add the degree sign to the 30-45
- Slides:
  - "First Metre of Slide Containing Platform Wall Height (m)" => "First Metre of Slide Wall Height (m)"
  - "Remaining Slide Containing Platform Wall Height (m)" => "Remaining Slide Wall Height (m)"

## Field Additions

- Blowers:
  - Number of Blowers
