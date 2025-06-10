# Units seed data (British terminology)

puts "Creating units..."

# Create units for test user (all units will be linked to test user)
castle_standard = Unit.create!(
  user: $test_user,
  name: "Medieval Castle Bouncer",
  serial: "ACQ-2021-#{rand(1000..9999)}",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Castle Deluxe 15",
  owner: "Stef's Castles",
  description: "15ft x 15ft medieval themed bouncy castle with turrets",
  width: 4.5,
  length: 4.5,
  height: 3.5,
  has_slide: false,
  is_totally_enclosed: false
)

castle_large = Unit.create!(
  user: $test_user,
  name: "Giant Party Castle",
  serial: "BCN-2020-#{rand(1000..9999)}",
  manufacturer: "Bouncy Castle Boys",
  model: "Mega Castle 30",
  owner: "Estephan Events",
  description: "30ft x 30ft large bouncy castle suitable for 20+ children",
  width: 9.0,
  length: 9.0,
  height: 4.5,
  has_slide: false,
  is_totally_enclosed: false
)

castle_slide_combo = Unit.create!(
  user: $test_user,
  name: "Princess Castle with Slide",
  serial: "J4J-2022-#{rand(1000..9999)}",
  manufacturer: "Jump4Joy Inflatables",
  model: "Princess Combo DLX",
  owner: "Stefan's Fun Factory",
  description: "Pink princess themed castle with integrated 8ft slide",
  width: 5.5,
  length: 7.0,
  height: 4.0,
  has_slide: true,
  is_totally_enclosed: false
)

soft_play_unit = Unit.create!(
  user: $test_user,
  name: "Toddler Soft Play Centre",
  serial: "CIU-2023-#{rand(1000..9999)}",
  manufacturer: "Custom Inflatables UK",
  model: "Soft Play Junior",
  owner: "Steff's Soft Play",
  description: "Fully enclosed soft play area for under 5s",
  width: 6.0,
  length: 6.0,
  height: 2.5,
  has_slide: false,
  is_totally_enclosed: true
)

obstacle_course = Unit.create!(
  user: $test_user,
  name: "Assault Course Challenge",
  serial: "IWL-2021-#{rand(1000..9999)}",
  manufacturer: "Inflatable World Ltd",
  model: "Obstacle Pro 40",
  owner: "Stephan's Adventure Co",
  description: "40ft assault course with obstacles, tunnels and slide finish",
  width: 3.0,
  length: 12.0,
  height: 3.5,
  has_slide: true,
  is_totally_enclosed: false
)

giant_slide = Unit.create!(
  user: $test_user,
  name: "Mega Slide Experience",
  serial: "ACQ-2019-#{rand(1000..9999)}",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Giant Slide 25",
  owner: "Stefan Family Inflatables",
  description: "25ft platform height giant inflatable slide",
  width: 5.0,
  length: 15.0,
  height: 7.5,
  has_slide: true,
  is_totally_enclosed: false
)

gladiator_duel = Unit.create!(
  user: $test_user,
  name: "Gladiator Duel Platform",
  serial: "HHE-2022-#{rand(1000..9999)}",
  manufacturer: "Happy Hop Europe",
  model: "Gladiator Arena",
  owner: "Stefano's Party Hire",
  description: "Inflatable gladiator duel platform with pedestals",
  width: 6.0,
  length: 6.0,
  height: 1.5,
  has_slide: false,
  is_totally_enclosed: false
)

bungee_run = Unit.create!(
  user: $test_user,
  name: "Double Bungee Run",
  serial: "PCM-2023-#{rand(1000..9999)}",
  manufacturer: "Party Castle Manufacturers",
  model: "Bungee Sprint Dual",
  owner: "Stef's Fun Factory",
  description: "Two lane inflatable bungee run competition game",
  width: 4.0,
  length: 10.0,
  height: 2.5,
  has_slide: false,
  is_totally_enclosed: false
)

# Make units available globally for inspections seed file
$castle_standard = castle_standard
$castle_large = castle_large
$castle_slide_combo = castle_slide_combo
$soft_play_unit = soft_play_unit
$obstacle_course = obstacle_course
$giant_slide = giant_slide
$gladiator_duel = gladiator_duel
$bungee_run = bungee_run

puts "Created #{Unit.count} units."