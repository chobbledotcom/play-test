# Shared test data helpers for generating realistic British data
# Used by both factories and seeds for non-critical test data generation
module TestDataHelpers
  # Generate realistic UK mobile numbers (07xxx format)
  def self.british_phone_number
    "07#{rand(100..999)} #{rand(100..999)} #{SecureRandom.hex(2).to_i(16) % 10000}"
  end

  # Generate realistic UK postcodes
  def self.british_postcode
    prefixes = %w[SW SE NW N E W EC WC B M L G EH CF BS OX CB]
    prefix = prefixes.sample
    letters = ("A".."Z").to_a
    "#{prefix}#{rand(1..20)} #{rand(1..9)}#{letters.sample}#{letters.sample}"
  end

  # Generate realistic UK street addresses
  def self.british_address
    streets = %w[
      High\ Street
      Church\ Lane
      Victoria\ Road
      King's\ Road
      Queen\ Street
      Park\ Avenue
      Station\ Road
      London\ Road
      Market\ Square
      The\ Green
    ]
    numbers = (1..200).to_a
    "#{numbers.sample} #{streets.sample}"
  end

  # Common British cities
  BRITISH_CITIES = %w[
    London
    Birmingham
    Manchester
    Leeds
    Liverpool
    Newcastle
    Bristol
    Sheffield
    Nottingham
    Leicester
    Oxford
    Cambridge
    Brighton
    Southampton
    Edinburgh
    Glasgow
    Cardiff
    Belfast
  ].freeze

  def self.british_city
    BRITISH_CITIES.sample
  end

  # Generate a British company name variation
  def self.british_company_name(base_name)
    suffixes = ["Ltd", "UK", "Services", "Solutions", "Group", "& Co"]
    "#{base_name} #{suffixes.sample}"
  end
end
