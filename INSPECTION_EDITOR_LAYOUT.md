# Unit Details

- Text boxes:

  - Description
  - Manufacturer
  - Size in metres
    - length
    - width
    - height
  - Serial Number
  - Unit Owner
  - Is Slide?
  - Is Totally Enclosed?

- Photo

# Useful Calculations

- Anchor points per side
- User counts only need to be calculated for the user height that applies
- The playing area doesn't include steps and if obstacles such as biff bash are present then you need to reduce this area

Judgement can be used here, but must be cautious considering over-loading and evacuation times do factor into this

# User Height / Count

- Tallest platform height (m)
- Tallest user height (m)
- Internal play area length (m)
- Internal Play Area width (m)
- Negative adjustment (m)
- Number of users at:
  - 1m
  - 1.2m
  - 1.5m
  - 1.8m

# Slide (if slide)

- number_comment: Slide platform height (m)
- number_comment: Containing wall height (m)
- number_comment: First metre of slide containing wall height (m)
- number_comment: Remaining slide containing wall height (m)
- boolean_comment: Permanent roof fitted to top of slide?
- pass_fail_comment: Steps / clamber netting
- number_pass_fail_comment: Slide run out (m)
- pass_fail_field: Slip sheet integrity

# Structure

- with pass/fail:
  - Seam integrity
  - Uses lock stitching?
  - Stich length (mm)
  - Air loss
  - Walls and towers vertical
  - No sharp, square angles, pointed cones
  - Blower tube length (m)
  - Is unit stable?
  - Safe evacuation time (seconds)
  - Step / ramp size (m)
  - Critical fall off Height (m)
  - Unit pressure (KPA)
  - Trough (has pass/fail, not sub-attributes)
    - Depth (mm)
    - Adjacent panel width (m)
  - Entrapment
  - Markings / ID
  - Grounding Test

# Anchorage

- number_pass_fail_comment - num_low_anchors - "Low anchor points"
- number_pass_fail_comment - num_high_anchors - "High anchor points"
- pass_fail_comment - anchor_accessories - "Correct anchor accessories"
- pass_fail_comment - anchor_degree - "Anchors between 30-45"
- pass_fail_comment - anchor_type - "Anchors permanently closed and metal"
- pass_fail_comment - pull_strength - "Pull strength test"

- Correct anchor accessories
- Anchors between 30-45 deg
- Anchors permanently closed and metal
- Pull strength test

# Totally Enclosed !

- number_pass_fail_comment - exit_number - "Number of exits"
- pass_fail_comment - exit_sign_always_visible - "Exit sign always visible"

# Materials

- number_pass_fail_comment - ropes - Ropes (mm)
- pass_fail_comment - clamber_netting - Clamber netting
- pass_fail_comment - retention_netting - Retention netting
- pass_fail_comment - zips - Zips
- pass_fail_comment - windows - Windows
- pass_fail_comment - artwork - Artwork
- pass_fail_comment - thread - Thread
- pass_fail_comment - fabric_strength - Fabric strength
- pass_fail_comment - fire_retardent - Fire retardent

# Fan

- text - fan_size_type - Blower size
- pass_fail_comment - blower_serial - Blower serial
- pass_fail_comment - blower_flap - Return flap present
- pass_fail_comment - blower_finger - Finger probe Test
- pass_fail_comment - pat - PAT
- pass_fail_comment - blower_visual - Visual Inspection

# Notes / risk assessment

- number_comment - width
- number_comment - length
- number_comment - height
- checkbox - has_slide
- checkbox - is_totally_enclosed
