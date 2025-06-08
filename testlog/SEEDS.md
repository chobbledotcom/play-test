# Seed Data Plan for TestLog

## Overview

This document outlines the seed data strategy for local development of the TestLog application. The seed data creates a realistic testing environment with various scenarios for inflatable equipment inspections.

## Data Generation Strategy

### Phase 1: Foundation Data

#### Inspector Companies (3 total)
1. **Bounce Safe Inspections Ltd** (Active)
   - RPII Registration: RPII-001
   - Full contact details
   - Logo attached
   - Main company for testing

2. **Kids Play Safety Services** (Active)
   - RPII Registration: RPII-002
   - Different region
   - Logo attached
   - Secondary active company

3. **Retired Inspections Co** (Archived)
   - RPII Registration: RPII-003
   - For testing archived company scenarios
   - No logo

#### Users (8 total)
1. **Admin User**
   - Email: admin@testlog.com
   - No company affiliation
   - For admin testing

2. **Lead Inspector** (Bounce Safe)
   - Email: lead@bouncesafe.com
   - Unlimited inspections (-1 limit)
   - Primary test user

3. **Junior Inspector** (Bounce Safe)
   - Email: junior@bouncesafe.com
   - Limited to 10 inspections
   - For testing limits

4. **Inspector** (Kids Play)
   - Email: inspector@kidsplay.com
   - Standard limits
   - Cross-company testing

5. **Archived Company User** (Retired Inspections)
   - Email: old@retired.com
   - For testing restrictions

6-8. **Additional Inspectors**
   - Various inspection limits (5, 20, unlimited)
   - Different activity patterns

### Phase 2: Equipment Data

#### Units (15-20 total)

**Categories:**
1. **Bouncy Castles** (5 units)
   - Standard castle (4m x 5m x 3m)
   - Large castle (8m x 10m x 4m)
   - Themed castle with slide
   - Totally enclosed soft play
   - Mini toddler unit

2. **Obstacle Courses** (3 units)
   - Standard assault course
   - Mega obstacle with slide
   - Enclosed ninja course

3. **Slides** (4 units)
   - Giant slide (platform 6m)
   - Water slide combo
   - Dry slide (platform 4m)
   - Toddler slide (platform 2m)

4. **Sports & Games** (3 units)
   - Gladiator duel platform
   - Bungee run
   - Inflatable football pitch

5. **Special Units** (3 units)
   - Unit needing repairs
   - Brand new unit (first inspection)
   - Very old unit (multiple inspection history)

**Manufacturers:**
- Airquee Manufacturing Ltd
- Bouncy Castle Network
- Jump4Joy Inflatables
- Happy Hop Europe
- Custom Inflatables UK

### Phase 3: Inspection History

#### Inspection Patterns (40-50 total)

1. **Recent Inspections** (Last 30 days)
   - Mix of passed/failed
   - Various assessment completions

2. **Historical Data** (Past year)
   - Quarterly inspections for some units
   - Annual inspections for others
   - Show inspection trends

3. **Status Variations**
   - 10 Draft inspections
   - 15 In Progress
   - 20 Completed
   - 5 Finalized

4. **Edge Cases**
   - Inspection with all assessments failed
   - Inspection with mixed results
   - Inspection with detailed recommendations

### Phase 4: Assessment Data

For each inspection, create realistic assessment data:

1. **Anchorage Assessments**
   - Varying anchor counts (4-16)
   - Mix of webbing/rope anchors
   - Some with wear issues

2. **Structure Assessments**
   - Pressure readings (1-5 mbar)
   - Evacuation times (30-180 seconds)
   - Seam integrity variations

3. **Materials Assessments**
   - Different rope sizes
   - Fabric condition variations
   - Fire certificate status

4. **Fan Assessments**
   - PAT test dates
   - Guard condition
   - Serial number tracking

5. **Slide Assessments** (where applicable)
   - Platform heights (2-6m)
   - Wall heights
   - Runout measurements

6. **User Height Assessments**
   - Capacity calculations
   - Age group restrictions

7. **Enclosed Assessments** (where applicable)
   - Exit visibility
   - Emergency exit checks

## Implementation Details

### Seed Data Organization

```ruby
# db/seeds.rb structure
Rails.logger = Logger.new(STDOUT)

# Clear existing data (development only)
if Rails.env.development?
  cleanup_existing_data
end

# Phase 1: Companies and Users
create_inspector_companies
create_users

# Phase 2: Equipment
create_units_for_each_user

# Phase 3: Inspections
create_inspection_history

# Phase 4: Current work
create_draft_inspections
create_in_progress_inspections

# Phase 5: Edge cases
create_edge_case_scenarios

# Summary
print_seed_summary
```

### Key Scenarios to Test

1. **User Permissions**
   - Admin access to all data
   - Company-limited visibility
   - Archived company restrictions

2. **Inspection Workflows**
   - Creating from unit history
   - Creating new unit during inspection
   - Copying dimensions
   - Assessment progression

3. **Business Rules**
   - Inspection limits
   - Reinspection due dates
   - Finalization requirements
   - Company archiving effects

4. **UI/UX Testing**
   - Table pagination
   - Search functionality
   - Filter combinations
   - Auto-save features

### Development Tips

1. **Consistent Data**
   - Use predictable patterns for easy identification
   - Include Unicode/special characters for edge testing
   - Realistic UK addresses and phone numbers

2. **Time-based Data**
   - Spread inspections across 18 months
   - Include future-dated drafts
   - Show inspection due soon/overdue

3. **File Attachments**
   - Sample logos for companies
   - Unit photos (different sizes/formats)
   - Test PDF generation scenarios

4. **Performance Testing**
   - Create enough data for pagination
   - Multiple inspections per unit
   - Large assessment datasets

## Execution Commands

```bash
# Run seeds
rails db:seed

# Reset and reseed
rails db:reset

# Selective seeding (with environment variables)
SEED_USERS_ONLY=true rails db:seed
SEED_MINIMAL=true rails db:seed
SEED_PERFORMANCE=true rails db:seed  # Creates 1000+ records
```

## Maintenance

- Update seed data when new features are added
- Test seed data after schema changes
- Keep factory patterns in sync with seeds
- Document any special test scenarios