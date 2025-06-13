puts "Creating users..."

def generate_secure_password
  SecureRandom.alphanumeric(32)
end

def create_user(email:, name:, rpii_number:, company:, active_until: Date.current + 1.year)
  User.create!(
    email: email,
    name: name,
    password: generate_secure_password,
    rpii_inspector_number: rpii_number,
    inspection_company: company,
    active_until: active_until
  )
end

$test_user = create_user(
  email: "test@play-test.co.uk",
  name: "Test User",
  rpii_number: "RPII-001",
  company: $stefan_testing
)

$lead_inspector = create_user(
  email: "lead@play-test.co.uk",
  name: "Lead Inspector",
  rpii_number: "RPII-002",
  company: $stefan_testing
)

create_user(
  email: "junior@play-test.co.uk",
  name: "Junior Inspector",
  rpii_number: "RPII-003",
  company: $stefan_testing
)

create_user(
  email: "senior@play-test.co.uk",
  name: "Senior Inspector",
  rpii_number: "RPII-004",
  company: $stefan_testing
)

$steph_test_inspector = create_user(
  email: "inspector@play-test.co.uk",
  name: "Steph Inspector",
  rpii_number: "RPII-005",
  company: $steph_test
)

create_user(
  email: "old@play-test.co.uk",
  name: "Expired Inspector",
  rpii_number: "RPII-006",
  company: $steve_inflatable,
  active_until: Date.current - 1.day
)

puts "Created #{User.count} users."
