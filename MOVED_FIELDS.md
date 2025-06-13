# Fields Moved from Inspections to Assessment Tables

## Anchorage Assessment Fields
- `num_low_anchors`
- `num_high_anchors`
- `num_low_anchors_comment`
- `num_high_anchors_comment`

## User Height Assessment Fields
- `containing_wall_height`
- `platform_height`
- `tallest_user_height`
- `users_at_1000mm`
- `users_at_1200mm`
- `users_at_1500mm`
- `users_at_1800mm`
- `play_area_length`
- `play_area_width`
- `negative_adjustment`
- `permanent_roof`
- All associated comment fields

## Slide Assessment Fields
- `slide_platform_height`
- `slide_wall_height`
- `runout`
- `slide_first_metre_height`
- `slide_beyond_first_metre_height`
- `clamber_netting_pass`
- `runout_pass`
- `slip_sheet_pass`
- `slide_permanent_roof`
- All associated comment fields

## Structure Assessment Fields
- `stitch_length`
- `evacuation_time`
- `unit_pressure_value`
- `blower_tube_length`
- `step_size_value`
- `fall_off_height_value`
- `trough_depth_value`
- `trough_width_value`
- `entrapment_pass`
- `markings_id_pass`
- `grounding_pass`
- `trough_pass`

## Materials Assessment Fields
- `rope_size` (now `ropes`)
- `artwork_pass`
- `windows_pass`
- `zips_pass`
- `retention_netting_pass`

## Enclosed Assessment Fields
- `exit_number`
- `exit_sign_visible_pass`
- `exit_number_comment`

## Access Pattern Changes Needed

### OLD:
```ruby
inspection.num_low_anchors
inspection.containing_wall_height
inspection.slide_platform_height
```

### NEW:
```ruby
inspection.anchorage_assessment.num_low_anchors
inspection.user_height_assessment.containing_wall_height
inspection.slide_assessment.slide_platform_height
```