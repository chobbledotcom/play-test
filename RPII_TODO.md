# RPII / Play Spec Changes

I've grouped the tasks into related sections and have given a time for how long each section will take me. I'll create public "Issues" for each of these sections on the Play-Test source code repository and will keep you posted on its progress - and you'll be able to see the source code changes in there too.

- Total Minutes: 300
- Total Hours: 5h
- Total £s: 500

## "Continue" change

**Time: 30m**

Rename to "Save Asssement" to "Continue", and have it automatically continue to the next page if there's no issues with the calculations, otherwise show the issue - and a link to continue anyway

## Branding

**Time: 45m**

Copy RPII's branding from their #BounceSafe page to create an RPII "theme", and then force that theme to be set for all users of the RPII's instance. Also, make the homepage and about page HTML editable by admins.

## Field Deletions

**Time: 20m**

- Inspection
  - Inspection Location
- Structure Assessment
  - Uses Lock Stitching
- Slides
  - Slide Platform Height
- Units
  - Model

## N/A Fields

**Time: 30m**

- Materials
  - Retention Netting
  - Zips
  - Windows
  - Artwork
- Fan/Blower
  - Return flap present
  - PAT

## Field Moves Between Assessments

**Time: 10m**

- User Height/Count
  - Platform Height => move to structure after step/ramp size

## Field Moves On Assessments

**Time: 10m**

- User Height/Count
  - Maximum User Height => move to User Capacity box after the pre-set sizes
  - User count at maximum user height => add below the above

## Field Changes

**Time: 45m**

- Stucture
  - Stitch Length => Pass/Fail/Comment
  - Blower Tube Length => not required to store number
  - Evacuation Time => remove number, just pass/fail/comment
  - Trough Adjacent Panel Width => convert to mm
  - Trough Depth & Trough Adjacent Panel Width" => remove pass/fails, keep number, keep "Trough Check"
- Blower
  - Blower Serial => remove pass/fail/comment

## Small Changes

**Time: 10m**

- Risk Assessment => make box significantly bigger by default
- Mark as complete - "By continuing you confirm that the data you have entered is accurate"

---

# Done

## Text Renames

**Time: 30m**

"Owner" => "Operator"
"Straight Walls" => "Vertical Walls (+/- 5%)"
"Sharp Edges" => "Sharp Angles or Oblique Edges"
"Unit Stable" => "Unit Stability"
"Critical Fall Off Height" => "Fall Off Height"
"Negative Adjustment" => "Negative Play Space Adjustment (m2)"
"Tallest User Height" => "Maximum User Height"

Slides - "Containing Wall Height" => "Containing Platform Wall Height"

## Indoor / Anchorage change

**Time: 15m**

- Add new field to inspections and units, "indoor_only"
- Exclude the anchorage section if that's selected

## Additional Inspection Images

**Time: 45m**

Add a link inside inspection results to upload images

- Maximum 3 per inspection
- Compress them
- Show links in the reports: Photo 1, 2, 3

## Users

**Time: 10m**

Add "Activate" and "Deactivate" buttons which sets active_until date
