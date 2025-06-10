puts "Creating units..."

def create_unit(name:, serial_prefix:, manufacturer:, model:, owner:, description:, width:, length:, height:, has_slide: false, is_totally_enclosed: false)
  Unit.create!(
    user: $test_user,
    name: name,
    serial: "#{serial_prefix}-#{rand(1000..9999)}",
    manufacturer: manufacturer,
    model: model,
    owner: owner,
    description: description,
    width: width,
    length: length,
    height: height,
    has_slide: has_slide,
    is_totally_enclosed: is_totally_enclosed
  )
end

$castle_standard = create_unit(
  name: "Medieval Castle Bouncer",
  serial_prefix: "ACQ-2021",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Castle Deluxe 15",
  owner: "Stef's Castles",
  description: "15ft x 15ft medieval themed bouncy castle with turrets",
  width: 4.5,
  length: 4.5,
  height: 3.5
)

$castle_large = create_unit(
  name: "Giant Party Castle",
  serial_prefix: "BCN-2020",
  manufacturer: "Bouncy Castle Boys",
  model: "Mega Castle 30",
  owner: "Estephan Events",
  description: "30ft x 30ft large bouncy castle suitable for 20+ children",
  width: 9.0,
  length: 9.0,
  height: 4.5
)

$castle_slide_combo = create_unit(
  name: "Princess Castle with Slide",
  serial_prefix: "J4J-2022",
  manufacturer: "Jump4Joy Inflatables",
  model: "Princess Combo DLX",
  owner: "Stefan's Fun Factory",
  description: "Pink princess themed castle with integrated 8ft slide",
  width: 5.5,
  length: 7.0,
  height: 4.0,
  has_slide: true
)

$soft_play_unit = create_unit(
  name: "Toddler Soft Play Centre",
  serial_prefix: "CIU-2023",
  manufacturer: "Custom Inflatables UK",
  model: "Soft Play Junior",
  owner: "Steff's Soft Play",
  description: "Fully enclosed soft play area for under 5s",
  width: 6.0,
  length: 6.0,
  height: 2.5,
  is_totally_enclosed: true
)

$obstacle_course = create_unit(
  name: "Assault Course Challenge",
  serial_prefix: "IWL-2021",
  manufacturer: "Inflatable World Ltd",
  model: "Obstacle Pro 40",
  owner: "Stephan's Adventure Co",
  description: "40ft assault course with obstacles, tunnels and slide finish",
  width: 3.0,
  length: 12.0,
  height: 3.5,
  has_slide: true
)

$giant_slide = create_unit(
  name: "Mega Slide Experience",
  serial_prefix: "ACQ-2019",
  manufacturer: "Airquee Manufacturing Ltd",
  model: "Giant Slide 25",
  owner: "Stefan Family Inflatables",
  description: "25ft platform height giant inflatable slide",
  width: 5.0,
  length: 15.0,
  height: 7.5,
  has_slide: true
)

$gladiator_duel = create_unit(
  name: "Gladiator Duel Platform",
  serial_prefix: "HHE-2022",
  manufacturer: "Happy Hop Europe",
  model: "Gladiator Arena",
  owner: "Stefano's Party Hire",
  description: "Inflatable gladiator duel platform with pedestals",
  width: 6.0,
  length: 6.0,
  height: 1.5
)

$bungee_run = create_unit(
  name: "Double Bungee Run",
  serial_prefix: "PCM-2023",
  manufacturer: "Party Castle Manufacturers",
  model: "Bungee Sprint Dual",
  owner: "Stef's Fun Factory",
  description: "Two lane inflatable bungee run competition game",
  width: 4.0,
  length: 10.0,
  height: 2.5
)

puts "Created #{Unit.count} units."
