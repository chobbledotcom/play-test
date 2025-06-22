Rails.logger.debug "Creating inspector companies..."

def create_inspector_company(name:, email:, city:, active:, notes:)
  InspectorCompany.create!(
    name: name,
    email: email,
    phone: TestDataHelpers.british_phone_number,
    address: TestDataHelpers.british_address,
    city: city,
    postal_code: TestDataHelpers.british_postcode,
    country: "UK",
    active: active,
    notes: notes
  )
end

$stefan_testing = create_inspector_company(
  name: "Stefan's Testing Co",
  email: "info@play-test.co.uk",
  city: "Birmingham",
  active: true,
  notes: "Premier inflatable inspection service in the Midlands. Established 2015."
)

$steph_test = create_inspector_company(
  name: "Steph Test",
  email: "enquiries@play-test.co.uk",
  city: "Manchester",
  active: true,
  notes: "Specialising in soft play and inflatable safety across the North West."
)

$steve_inflatable = create_inspector_company(
  name: "Steve Inflatable Testing",
  email: "old@play-test.co.uk",
  city: "London",
  active: false,
  notes: "Company ceased trading in 2023. Records maintained for historical purposes."
)

Rails.logger.debug { "Created #{InspectorCompany.count} inspector companies." }
