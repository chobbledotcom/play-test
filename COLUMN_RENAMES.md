# Column Rename Mappings

## Inspections Table
- `equipment_id` → `unit_id`
- `place_inspected` → `inspection_location`
- `user_height` → `tallest_user_height`
- `runout_value` → `runout`
- `runout_value_comment` → `runout_comment`

## Units Table
- `user_height` → `tallest_user_height`
- `runout_value` → `runout`
- `runout_value_comment` → `runout_comment`

## User Height Assessments
- `user_height` → `tallest_user_height`
- `user_height_comment` → `tallest_user_height_comment`

## Materials Assessments
- `rope_size` → `ropes`
- `rope_size_pass` → `ropes_pass`
- `rope_size_comment` → `ropes_comment`
- `fabric_pass` → `fabric_strength_pass` → `fabric_pass` (reverted)
- `clamber_pass` → `clamber_netting_pass`
- `clamber_comment` → `clamber_netting_comment`
- `equipment_storage` → `unit_storage`

## Enclosed Assessments
- `exit_visible_pass` → `exit_sign_always_visible_pass`
- `exit_visible_comment` → `exit_sign_always_visible_comment`

## Slide Assessments
- `runout_value` → `runout`

## Fan Assessments
- `fan_size_comment` → `fan_size_type`

## Final State (What to use in fixes)
- `rope_size` → `ropes`
- `user_height` → `tallest_user_height`
- `exit_visible_pass` → `exit_sign_always_visible_pass`
- `runout_value` → `runout`
- `clamber_pass` → `clamber_netting_pass`
- `equipment_id` → `unit_id`
- `place_inspected` → `inspection_location`
- `fan_size_comment` → `fan_size_type`