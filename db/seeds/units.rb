Rails.logger.debug "Creating units..."

# Create badge batch and badges for all units
badge_batch = BadgeBatch.create!(note: "Seed data badges", count: 8)
badges = 8.times.map { Badge.create!(badge_batch: badge_batch) }
badge_ids = badges.map(&:id)

def create_unit(name:, serial_prefix:, manufacturer:, operator:, description:, badge_id:)
  Unit.create!(
    SeedData.unit_fields.merge(
      id: badge_id,
      user: $test_user,
      name: name,
      serial: "#{serial_prefix}-#{SecureRandom.hex(4).upcase}",
      manufacturer: manufacturer,
      operator: operator,
      description: description,
      is_seed: true
    )
  )
end

$castle_standard = create_unit(
  name: "Medieval Castle Bouncer",
  serial_prefix: "ACQ-2021",
  manufacturer: "Airquee Manufacturing Ltd",
  operator: "Stef's Castles",
  description: "15ft x 15ft medieval themed bouncy castle with turrets",
  badge_id: badge_ids[0]
)

$castle_large = create_unit(
  name: "Giant Party Castle",
  serial_prefix: "BCN-2020",
  manufacturer: "Bouncy Castle Boys",
  operator: "Estephan Events",
  description: "30ft x 30ft large bouncy castle suitable for 20+ children",
  badge_id: badge_ids[1]
)

$castle_slide_combo = create_unit(
  name: "Princess Castle with Slide",
  serial_prefix: "J4J-2022",
  manufacturer: "Jump4Joy Inflatables",
  operator: "Stefan's Fun Factory",
  description: "Pink princess themed castle with integrated 8ft slide",
  badge_id: badge_ids[2]
)

$soft_play_unit = create_unit(
  name: "Toddler Soft Play Centre",
  serial_prefix: "CIU-2023",
  manufacturer: "Custom Inflatables UK",
  operator: "Steff's Soft Play",
  description: "Fully enclosed soft play area for under 5s",
  badge_id: badge_ids[3]
)

$obstacle_course = create_unit(
  name: "Assault Course Challenge",
  serial_prefix: "IWL-2021",
  manufacturer: "Inflatable World Ltd",
  operator: "Stephan's Adventure Co",
  description: "40ft assault course with obstacles, tunnels and slide finish",
  badge_id: badge_ids[4]
)

$giant_slide = create_unit(
  name: "Mega Slide Experience",
  serial_prefix: "ACQ-2019",
  manufacturer: "Airquee Manufacturing Ltd",
  operator: "Stefan Family Inflatables",
  description: "25ft platform height giant inflatable slide",
  badge_id: badge_ids[5]
)

$gladiator_duel = create_unit(
  name: "Gladiator Duel Platform",
  serial_prefix: "HHE-2022",
  manufacturer: "Happy Hop Europe",
  operator: "Stefano's Party Hire",
  description: "Inflatable gladiator duel platform with pedestals",
  badge_id: badge_ids[6]
)

$bungee_run = create_unit(
  name: "Double Bungee Run",
  serial_prefix: "PCM-2023",
  manufacturer: "Party Castle Manufacturers",
  operator: "Stef's Fun Factory",
  description: "Two lane inflatable bungee run competition game",
  badge_id: badge_ids[7]
)

Rails.logger.debug { "Created #{Unit.count} units." }
