# Inspector Companies seed data

puts "Creating inspector companies..."

stefan_testing = InspectorCompany.create!(
  name: "Stefan's Testing Co",
  email: "info@play-test.co.uk",
  phone: TestDataHelpers.british_phone_number,
  address: TestDataHelpers.british_address,
  city: "Birmingham",
  postal_code: TestDataHelpers.british_postcode,
  country: "UK",
  active: true,
  notes: "Premier inflatable inspection service in the Midlands. Established 2015."
)

steph_test = InspectorCompany.create!(
  name: "Steph Test",
  email: "enquiries@play-test.co.uk",
  phone: TestDataHelpers.british_phone_number,
  address: TestDataHelpers.british_address,
  city: "Manchester",
  postal_code: TestDataHelpers.british_postcode,
  country: "UK",
  active: true,
  notes: "Specialising in soft play and inflatable safety across the North West."
)

steve_inflatable = InspectorCompany.create!(
  name: "Steve Inflatable Testing",
  email: "old@play-test.co.uk",
  phone: TestDataHelpers.british_phone_number,
  address: TestDataHelpers.british_address,
  city: "London",
  postal_code: TestDataHelpers.british_postcode,
  country: "UK",
  active: false,
  notes: "Company ceased trading in 2023. Records maintained for historical purposes."
)

# Make companies available globally for other seed files
$stefan_testing = stefan_testing
$steph_test = steph_test
$steve_inflatable = steve_inflatable

puts "Created #{InspectorCompany.count} inspector companies."