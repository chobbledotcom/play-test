# Shared test data helpers for generating realistic British data
# Used by both factories and seeds for non-critical test data generation
module TestDataHelpers
  # Generate realistic UK mobile numbers (07xxx format)
  def self.british_phone_number
    "07#{rand(100..999)} #{rand(100..999)} #{rand(1000..9999)}"
  end

  # Generate realistic UK postcodes
  def self.british_postcode
    prefixes = [ "SW", "SE", "NW", "N", "E", "W", "EC", "WC", "B", "M", "L", "G", "EH", "CF", "BS", "OX", "CB" ]
    "#{prefixes.sample}#{rand(1..20)} #{rand(1..9)}#{("A".."Z").to_a.sample}#{("A".."Z").to_a.sample}"
  end

  # Generate realistic UK street addresses
  def self.british_address
    streets = [ "High Street", "Church Lane", "Victoria Road", "King's Road", "Queen Street",
      "Park Avenue", "Station Road", "London Road", "Market Square", "The Green" ]
    numbers = (1..200).to_a
    "#{numbers.sample} #{streets.sample}"
  end

  # Common British cities
  def self.british_city
    [ "London", "Birmingham", "Manchester", "Leeds", "Liverpool", "Newcastle", "Bristol",
      "Sheffield", "Nottingham", "Leicester", "Oxford", "Cambridge", "Brighton", "Southampton",
      "Edinburgh", "Glasgow", "Cardiff", "Belfast" ].sample
  end

  # Generate a British company name variation
  def self.british_company_name(base_name)
    suffixes = [ "Ltd", "UK", "Services", "Solutions", "Group", "& Co", "International" ]
    "#{base_name} #{suffixes.sample}"
  end

  # Generate inspection location
  def self.inspection_location
    venues = [ "Park", "Recreation Centre", "Community Hall", "School", "Leisure Centre",
      "Sports Complex", "Village Hall", "Town Square", "Festival Grounds" ]
    "#{british_city} #{venues.sample}"
  end
end
