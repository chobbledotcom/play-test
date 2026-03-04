# Plan: Add 5 New Unit Types (Chunked, Simplest First)

## Context

Spencer's C# desktop app defines inspection checks for inflatable equipment types beyond bouncy castles. We're adding 5 new unit types one at a time, each as a self-contained chunk that can be tested before moving to the next. Simplest first to validate the pattern.

## Chunk Overview

| Order | Unit Type | Unique Assessment | Shared Assessments | Conditionals | Status |
|---|---|---|---|---|---|
| 1 | `inflatable_ball_pool` | `ball_pool_assessment` (9 fields) | structure, materials, fan | none | |
| 2 | `inflatable_game` | `inflatable_game_assessment` (9 fields) | structure, materials, fan | none | |
| 3 | `catch_bed` | `catch_bed_assessment` (15 fields) | structure, materials, fan, anchorage | none | |
| 4 | `bungee_run` | `bungee_assessment` (19 fields) | structure, materials, fan, anchorage | none | |
| 5 | `play_zone` | `play_zone_assessment` (14 fields) | structure, materials, fan, user_height, slide | `has_slide` toggle | |

## Per-Chunk Recipe

Each chunk creates/modifies these files atomically:

### Create:
1. `db/migrate/TIMESTAMP_create_{name}_assessments.rb` — migration
2. `app/models/assessments/{name}_assessment.rb` — model
3. `config/forms/{name}_assessment.yml` — YAML form config
4. `config/locales/forms/{name}.en.yml` — i18n translations
5. `app/controllers/{name}_assessments_controller.rb` — controller
6. `spec/factories/{name}_assessments.rb` — test factory

### Modify:
7. `app/models/unit.rb` — add enum value
8. `app/models/inspection.rb` — add enum, constant, assessment_types, applicable_assessments, applicable_tabs, can_be_completed?, assessment_validation_data
9. `config/locales/units.en.yml` — add display name
10. `app/views/units/_form.html.erb` — add to select dropdown

### Test:
```bash
bundle exec rails db:migrate && bundle exec rails parallel:prepare && bin/test
```

---

## Chunk 1: Inflatable Ball Pool

### Ball Pool Assessment Fields
| Field | Type | Description |
|---|---|---|
| age_range_marking | pass/comment | Marking to indicate age range |
| max_height_markings | pass/comment | Marking to indicate max user height |
| suitable_matting | pass/comment | Suitable matting |
| air_jugglers_compliant | pass/comment | Air jugglers compliant |
| balls_compliant | pass/comment | Balls compliant |
| gaps | pass/comment | No gaps in ball pool |
| fitted_base | pass/comment | Fitted base sheet |
| ball_pool_depth | integer(mm) + pass/comment | Ball pool depth max 450mm |
| ball_pool_entry | integer(mm) + pass/comment | Ball pool entry height max 630mm |

---

## Chunk 2: Inflatable Game

### Inflatable Game Assessment Fields
| Field | Type | Description |
|---|---|---|
| game_type | text (comment only) | Type of inflatable game description |
| max_user_mass | pass/comment | Marking for max user mass |
| age_range_marking | pass/comment | Marking to indicate age range |
| constant_air_flow | pass/comment | Inflatable is constant air-flow unit |
| design_risk | pass/comment | Design and construction minimises risk |
| intended_play_risk | pass/comment | Intended play minimises risk |
| ancillary_equipment | pass/comment | Ancillary equipment fit for purpose |
| ancillary_equipment_compliant | pass/comment | Ancillary equipment compliant |
| containing_wall_height | decimal(m) + pass/comment | Containing wall height |

---

## Chunk 3: Catch Bed

### Catch Bed Assessment Fields
| Field | Type | Description |
|---|---|---|
| type_of_unit | text (comment only) | Type of catch bed description |
| max_user_mass_marking | pass/comment | Marking for max user mass |
| arrest | pass/comment | Bed suitable to arrest users when falling |
| matting | pass/comment | Suitable matting |
| design_risk | pass/comment | Design and construction minimises risk |
| intended_play | pass/comment | Intended play minimises risk |
| ancillary_fit | pass/comment | Ancillary equipment fit for purpose |
| ancillary_compliant | pass/comment | Ancillary equipment compliant |
| apron | pass/comment | Suitable apron and padding |
| trough | pass/comment | Trough depth suitable |
| framework | pass/comment | Framework secure |
| grounding | pass/comment | 120kg grounding test |
| bed_height | integer(mm) + pass/comment | Bed height minimum 400mm |
| platform_fall_distance | decimal(m) + pass/comment | Distance from platform edge to containing wall |
| blower_tube_length | decimal(m) + pass/comment | Blower tube length at least 2.5m |

---

## Chunk 4: Bungee Run

### Bungee Assessment Fields
| Field | Type | Description |
|---|---|---|
| blower_forward_distance | pass/comment | Blower no more than 1.5m forward of rear wall |
| marking_max_mass | pass/comment | Marking for max user mass 120kg |
| marking_min_height | pass/comment | Marking for minimum user height 1.2m |
| pull_strength | pass/comment | Harness pull strength test to 1200N |
| cord_length_max | pass/comment | All cords max length 3.3m |
| cord_diametre_min | pass/comment | All cord diameters min 12.5mm |
| two_stage_locking | pass/comment | Two-stage locking system present |
| baton_compliant | pass/comment | Baton is compliant |
| lane_width_max | pass/comment | Each lane max 900mm wide |
| harness_width | integer + pass/comment | Harness width in mm (default 200) |
| num_of_cords | integer | Number of cords (default 2) |
| rear_wall_thickness | decimal | Rear wall thickness in metres (default 0.6) |
| rear_wall_height | decimal | Rear wall height in metres (default 1.8) |
| rear_wall | pass/comment | Rear wall dimensions meets requirements |
| side_wall_length | decimal | Side wall length in metres (default 1.5) |
| side_wall_height | decimal | Side wall height in metres (default 1.7) |
| side_wall | pass/comment | Side wall dimensions meets requirements |
| running_wall_width | decimal | Running wall width in metres (default 0.45) |
| running_wall_height | decimal | Running wall height in metres (default 0.9) |
| running_wall | pass/comment | Running wall dimensions meets requirements |

---

## Chunk 5: Play Zone (has conditional: has_slide)

### Play Zone Assessment Fields
| Field | Type | Description |
|---|---|---|
| age_marking | pass/comment | Marking to indicate age range |
| height_marking | pass/comment | Marking to indicate max user height |
| sight_line | pass/comment | Sight lines clear to observe playing areas |
| access | pass/comment | Access, egress and connections safe |
| suitable_matting | pass/comment | Suitable matting |
| traffic_flow | pass/comment | Traffic flow design safe |
| air_juggler | pass/comment | Air jugglers compliant |
| balls | pass/comment | Balls compliant |
| ball_pool_gaps | pass/comment | No gaps in ball pool |
| fitted_sheet | pass/comment | Fitted base sheet |
| ball_pool_depth | integer(mm) + pass/comment | Ball pool depth max 450mm |
| ball_pool_entry_height | integer(mm) + pass/comment | Ball pool entry height max 630mm |
| slide_gradient | integer(deg) + pass/comment | Platform incline gradient max 64 deg |
| slide_platform_height | decimal(m) + pass/comment | Slide platform height max 1.5m |

### Extra for play_zone only:
- `slide_assessment` conditionally included when `has_slide?` is true
- Inspection form must show `has_slide` checkbox for play_zone inspections
- `can_be_completed?` needs `!has_slide.nil?`
