# Plan: Add 5 New Unit Types from Spencer's App

## Context

Spencer's C# desktop app (`spencers_app/Form1.cs`) defines inspection checks for several inflatable equipment types beyond bouncy castles. Our Rails app currently supports 3 unit types (bouncy_castle, bouncing_pillow, pat_testable) with 8 assessment models. We need to add 5 new unit types, each with their own unique assessment plus shared assessments reused from the existing bouncy castle type.

The architecture is already extensible — assessment models are config-driven via YAML, routes auto-generate from `ALL_ASSESSMENT_TYPES`, and controllers use a shared concern.

## New Unit Types & Their Assessments

| Unit Type | Unique Assessment | Shared Assessments | Conditionals |
|---|---|---|---|
| `bungee_run` | `bungee_assessment` | structure, materials, fan, anchorage | none |
| `play_zone` | `play_zone_assessment` | structure, materials, fan, user_height | `has_slide` → slide_assessment |
| `inflatable_ball_pool` | `ball_pool_assessment` | structure, materials, fan | none |
| `inflatable_game` | `inflatable_game_assessment` | structure, materials, fan | none |
| `catch_bed` | `catch_bed_assessment` | structure, materials, fan, anchorage | none |

## Implementation Steps

### Step 1: Add unit type enums & translations

**Files to modify:**
- `app/models/unit.rb` — add 5 entries to `unit_type` enum
- `app/models/inspection.rb` — add 5 entries to `inspection_type` enum
- `config/locales/units.en.yml` — add display names

New enum values:
```ruby
bungee_run: "BUNGEE_RUN"
play_zone: "PLAY_ZONE"
inflatable_ball_pool: "INFLATABLE_BALL_POOL"
inflatable_game: "INFLATABLE_GAME"
catch_bed: "CATCH_BED"
```

### Step 2: Create 5 new assessment DB migrations

One migration per assessment table. Pattern: `id: false`, `inspection_id` string(12) as PK, foreign key to inspections.

**Files to create:**
1. `db/migrate/TIMESTAMP_create_bungee_assessments.rb` — 19 field groups from Spencer's spec (pass/comment + dimension values for walls, cords, harness)
2. `db/migrate/TIMESTAMP_create_play_zone_assessments.rb` — 14 field groups (pass/comment + pool depth, entry height, slide gradient values)
3. `db/migrate/TIMESTAMP_create_ball_pool_assessments.rb` — 9 field groups (pass/comment + pool depth/entry values)
4. `db/migrate/TIMESTAMP_create_inflatable_game_assessments.rb` — 9 field groups (pass/comment + wall height value)
5. `db/migrate/TIMESTAMP_create_catch_bed_assessments.rb` — 15 field groups (pass/comment + height/distance/length values)

### Step 3: Create 5 assessment models

Pattern: `app/models/assessments/anchorage_assessment.rb`. Includes: `AssessmentLogging`, `AssessmentCompletion`, `FormConfigurable`, `ValidationConfigurable`. PK is `inspection_id`.

**Files to create:**
1. `app/models/assessments/bungee_assessment.rb`
2. `app/models/assessments/play_zone_assessment.rb`
3. `app/models/assessments/ball_pool_assessment.rb`
4. `app/models/assessments/inflatable_game_assessment.rb`
5. `app/models/assessments/catch_bed_assessment.rb`

### Step 4: Create form config YAMLs

Pattern: `config/forms/anchorage_assessment.yml`. Partials: `:pass_fail_comment`, `:number_pass_fail_comment`, `:decimal_comment`, `:text_field`.

**Files to create:**
1. `config/forms/bungee_assessment.yml`
2. `config/forms/play_zone_assessment.yml`
3. `config/forms/ball_pool_assessment.yml`
4. `config/forms/inflatable_game_assessment.yml`
5. `config/forms/catch_bed_assessment.yml`

### Step 5: Create I18n locale files

Pattern: `config/locales/forms/anchorage.en.yml`. Field labels sourced from Spencer's PDF strings.

**Files to create:**
1. `config/locales/forms/bungee.en.yml`
2. `config/locales/forms/play_zone.en.yml`
3. `config/locales/forms/ball_pool.en.yml`
4. `config/locales/forms/inflatable_game.en.yml`
5. `config/locales/forms/catch_bed.en.yml`

### Step 6: Create 5 assessment controllers

Pattern: `app/controllers/pat_assessments_controller.rb` (minimal — just `include AssessmentController`).

**Files to create:**
1. `app/controllers/bungee_assessments_controller.rb`
2. `app/controllers/play_zone_assessments_controller.rb`
3. `app/controllers/ball_pool_assessments_controller.rb`
4. `app/controllers/inflatable_game_assessments_controller.rb`
5. `app/controllers/catch_bed_assessments_controller.rb`

### Step 7: Wire up in Inspection model

**File to modify:** `app/models/inspection.rb`

- Add 5 `*_ASSESSMENT_TYPES` constants mapping each unit type to its assessments
- Merge all into `ALL_ASSESSMENT_TYPES`
- Update `assessment_types` method — add branches for each new type
- Update `applicable_assessments` — add methods for each new type; play_zone conditionally includes slide_assessment based on `has_slide?`
- Update `applicable_tabs` ordered list — add `bungee`, `play_zone`, `ball_pool`, `inflatable_game`, `catch_bed`
- Update `can_be_completed?` — new types need dimensions but NOT castle-specific flags (except play_zone needs `has_slide` defined)
- Update `assessment_validation_data` — add 5 new assessment type symbols

### Step 8: Update unit form view

**File to modify:** `app/views/units/_form.html.erb` — add 5 new options to unit_type select

### Step 9: Update inspection form for play_zone

The play_zone type needs the `has_slide` checkbox on the inspection form (reusing the existing field). The inspection form config/view may need updating to show this checkbox for play_zone inspections as well as bouncy_castle inspections.

### Step 10: Create test factories

**Files to create:**
1. `spec/factories/bungee_assessments.rb`
2. `spec/factories/play_zone_assessments.rb`
3. `spec/factories/ball_pool_assessments.rb`
4. `spec/factories/inflatable_game_assessments.rb`
5. `spec/factories/catch_bed_assessments.rb`

### Step 11: Run migrations & tests

```bash
bundle exec rails db:migrate
bundle exec rails parallel:prepare
bin/test
```

## Field Details (from Spencer's app)

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
