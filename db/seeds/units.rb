require_relative "seed_data"

Rails.logger.debug "Creating units..."

def create_unit(name:, serial_prefix:, manufacturer:, model:, owner:, description:, notes: nil)
  Unit.create!(
    SeedData.unit_fields.merge(
      user: $test_user,
      name: name,
      serial: "#{serial_prefix}-#{rand(1000..9999)}",
      manufacturer: manufacturer,
      model: model,
      owner: owner,
      description: description,
      notes: notes,
      is_seed: true
    )
  )
end

$castle_standard = create_unit(
  name: "Medieval Castle Bouncer",
  serial_prefix: "ACQ-2021",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Castle Deluxe 15",
  owner: "Stef's Castles",
  description: "15ft x 15ft medieval themed bouncy castle with turrets",
  notes: "Popular rental unit, well-maintained"
)

$castle_large = create_unit(
  name: "Giant Party Castle",
  serial_prefix: "BCN-2020",
  manufacturer: "Bouncy Castle Boys",
  model: "Mega Castle 30",
  owner: "Estephan Events",
  description: "30ft x 30ft large bouncy castle suitable for 20+ children",
  notes: "Requires 2 blowers for proper inflation"
)

$castle_slide_combo = create_unit(
  name: "Princess Castle with Slide",
  serial_prefix: "J4J-2022",
  manufacturer: "Jump4Joy Inflatables",
  model: "Princess Combo DLX",
  owner: "Stefan's Fun Factory",
  description: "Pink princess themed castle with integrated 8ft slide",
  notes: "Slide section requires extra attention during inspection"
)

$soft_play_unit = create_unit(
  name: "Toddler Soft Play Centre",
  serial_prefix: "CIU-2023",
  manufacturer: "Custom Inflatables UK",
  model: "Soft Play Junior",
  owner: "Steff's Soft Play",
  description: "Fully enclosed soft play area for under 5s",
  notes: "Enclosed design - check all exit points carefully"
)

$obstacle_course = create_unit(
  name: "Assault Course Challenge",
  serial_prefix: "IWL-2021",
  manufacturer: "Inflatable World Ltd",
  model: "Obstacle Pro 40",
  owner: "Stephan's Adventure Co",
  description: "40ft assault course with obstacles, tunnels and slide finish",
  notes: "Multiple sections require individual inspection"
)

$giant_slide = create_unit(
  name: "Mega Slide Experience",
  serial_prefix: "ACQ-2019",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Giant Slide 25",
  owner: "Stefan Family Inflatables",
  description: "25ft platform height giant inflatable slide",
  notes: "High platform - safety barriers critical"
)

$gladiator_duel = create_unit(
  name: "Gladiator Duel Platform",
  serial_prefix: "HHE-2022",
  manufacturer: "Happy Hop Europe",
  model: "Gladiator Arena",
  owner: "Stefano's Party Hire",
  description: "Inflatable gladiator duel platform with pedestals",
  notes: "Check pedestal stability and padding"
)

$bungee_run = create_unit(
  name: "Double Bungee Run",
  serial_prefix: "PCM-2023",
  manufacturer: "Party Castle Manufacturers",
  model: "Bungee Sprint Dual",
  owner: "Stef's Fun Factory",
  description: "Two lane inflatable bungee run competition game",
  notes: "Bungee cords require regular inspection for wear"
)

Rails.logger.debug { "Created #{Unit.count} units." }
