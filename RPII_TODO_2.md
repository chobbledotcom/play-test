## Field Renames

**Time: 20m**

## Add Notes

**Time: 10m**

## Field Additions

**Time: 10m**

## Field Changes

**Time: 30m**

## Calculators

**Time: 20m**

## Layout

**Time: 30m** (more complicated than it seems - atm every field is required)

## PDF

**Time: 30m**

## Design

**Time: 0m**

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
- Anchorage
  - Add the degree sign to the 30-45
- Slides
  - "First Metre of Slide Containing Platform Wall Height (m)" => "First Metre of Slide Wall Height (m)"
  - "Remaining Slide Containing Platform Wall Height (m)" => "Remaining Slide Wall Height (m)"
- Inspection
  - Unit Name => Bounce Safe Number

For "Bounce Safe Number" I need to add per-site translations rather than per-language, because only one Play-Test site will be a #BounceSafe one, but I don't think that'll be too complicated.

## Field Additions

- Blowers:
  - Number of Blowers

## Field Changes

- Structure:
  - Platform height: change to mm
  - Fall off height: change to mm
- Structure:
  - Move blower tube length bit to blower section

## Calculators / Source Code

- Platform height (non slide) calculation - get Spencer's input

## Add Notes

- Structure:
  - Under main wall height: "This is not slides - that's the next page"
- Blowers:
  - "You must test and log for every blower for this unit"

## Calculators

- All:
  - Remove "Pass/Fail" from the calculation bits
  - Instead say something like "Under/above the calculated anchor points" in the breakdown
- Anchorage:
  - Make it clear that the calculation uses the box model
  - "Required anchors" => "Calculated **total** anchors required"

## Design

- Bigger logos

## Layout

- Ropes - not required when N/A is selected

## PDF

- Add a Disclaimer footer and fit signature in
- Move the photo up

## Bug Fixes (free)

- User Capacity => arrange the "Max users at X" fields horizontally
- PDF - Operator is listed twice

## Calculators

- Wall Heights:
  - If there's a permanent roof, we can skip the "Walls must be at least" message, make this clearer in the breakdown
